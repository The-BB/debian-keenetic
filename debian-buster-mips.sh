#!/bin/sh

# Working dir should stay here
SCRIPT_DIR=$(dirname $0)

ROOT_DIR=$SCRIPT_DIR/installer_root
BUILD_DIR=$SCRIPT_DIR/../Entware/build_dir/target-mips_mips32r2_glibc-*
INSTALLER=$SCRIPT_DIR/debian-buster-10_4-mips.tar.gz

# Compile libc and busybox from Entware first!
[ -d $BUILD_DIR ] || exit 1

[ -d $ROOT_DIR ] && rm -fr $ROOT_DIR
# Make hook scripts dirs, see https://github.com/ndmsystems/packages/wiki/Opkg-Component
#for dir in button fs neighbour netfilter schedule time usb user wan \
#	ifcreated ifdestroyed ifipchanged ifstatechanged \
#	l2tp_ipsec_vpn_up l2tp_ipsec_vpn_down pptp_vpn_up pptp_vpn_down	\
#	sstp_vpn_up sstp_vpn_down vip_vpn_up vip_vpn_down \
#	openvpn-up openvpn-down openvpn-route-up openvpn-ipchange
#	openvpn-client-connect openvpn-client-disconnect \
#	openvpn-learn-address openvpn-tls-verify; do
#    mkdir -p $ROOT_DIR/opt/etc/ndm/${dir}.d
#done
echo 'Adding hook scripts dirs'
mkdir -p $ROOT_DIR/opt/etc
cp -r $BUILD_DIR/opt-ndmsv2-*/ipkg-mips-3.4_kn/opt-ndmsv2/opt/etc/ndm $ROOT_DIR/opt/etc/

echo 'Adding toolchain libraries...'
cp -r $BUILD_DIR/toolchain/ipkg-mips-3.4/libc/opt $ROOT_DIR
cp -r $BUILD_DIR/toolchain/ipkg-mips-3.4/libgcc/opt $ROOT_DIR
cp -r $BUILD_DIR/toolchain/ipkg-mips-3.4/libpthread/opt $ROOT_DIR

echo 'Adding busybox...'
cp -r $BUILD_DIR/busybox-*/ipkg-install/opt $ROOT_DIR

echo 'Adding iptables...'
cp -r $BUILD_DIR/linux-mips-3.4/iptables-*/ipkg-mips-3.4/iptables/opt $ROOT_DIR

echo 'Adding Debian minimal...'
[ -f debian-buster-mips_clean.tgz ] || wget http://ndm.zyxmon.org/binaries/debian/debian-buster-mips_clean.tgz
[ -f debian-buster-mips_clean.tgz ]
sudo tar -xz -C $ROOT_DIR/opt -f debian-buster-mips_clean.tgz

# Set up Debian chroot
sudo sed -i -e 's|^#Port 22|Port 222|g' -e 's|^#PermitRootLogin .*|PermitRootLogin yes|' \
	$ROOT_DIR/opt/debian/etc/ssh/sshd_config
sudo touch $ROOT_DIR/opt/debian/chroot-services.list
sudo chmod 666 $ROOT_DIR/opt/debian/chroot-services.list
echo 'ssh' >> $ROOT_DIR/opt/debian/chroot-services.list
sudo mkdir $ROOT_DIR/opt/debian/opt/etc

# Set SourcesList, hostname & resolv.conf
sudo cat > $ROOT_DIR/opt/debian/etc/apt/sources.list <<EOF
deb http://ftp.debian.org/debian/ buster main non-free contrib
#deb-src http://ftp.debian.org/debian/ buster main non-free contrib
EOF

sudo echo 'debian_mips' > $ROOT_DIR/opt/debian/etc/hostname
sudo sed -i -e 's,^nameserver .*,nameserver 8.8.8.8,' $ROOT_DIR/opt/debian/etc/resolv.conf

echo 'Adding start script...'
mkdir -p $ROOT_DIR/opt/etc
cp $SCRIPT_DIR/initrc $ROOT_DIR/opt/etc
chmod +x $ROOT_DIR/opt/etc/initrc

echo 'Adding ndmq utility...'
sudo tar -xz -C $ROOT_DIR/opt/debian -f ndmq-mips_buster.tgz

echo 'Packing installer...'
[ -f $INSTALLER ] && rm -f $INSTALLER

# The lower compression gives -10 secs while unpacking on Omni II
#sudo tar -czf $INSTALLER -C $ROOT_DIR/opt bin etc lib sbin debian
sudo tar -I 'gzip -1' -cf $INSTALLER -C $ROOT_DIR/opt bin etc lib sbin debian

# Removing temp folder
sudo rm -fr $ROOT_DIR

echo "Done! Plug in EXT2/3/4 formatted USB drive to Keenetic, put $INSTALLER into \"install\" folder via SAMBA or FTP and activate OPKG component via WebUI."
