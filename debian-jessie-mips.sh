#!/bin/sh

# Working dir should stay here
SCRIPT_DIR=$(dirname $0)

ROOT_DIR=$SCRIPT_DIR/installer_root
BUILD_DIR=$SCRIPT_DIR/../Entware/build_dir/target-mips_mips32r2_glibc-*
INSTALLER=$SCRIPT_DIR/debian-jessie-8_11-mips.tar.gz

# Compile libc and busybox from Entware first!
[ -d $BUILD_DIR ] || exit 1

[ -d $ROOT_DIR ] && rm -fr $ROOT_DIR
# Make hook scripts dirs, see https://github.com/ndmsystems/packages/wiki/Opkg-Component
for dir in button fs netfilter schedule time usb user wan; do
    mkdir -p $ROOT_DIR/opt/etc/ndm/${dir}.d
done

echo 'Adding toolchain libraries...'
cp -r $BUILD_DIR/toolchain/ipkg-mips-3.4/libc/opt $ROOT_DIR
cp -r $BUILD_DIR/toolchain/ipkg-mips-3.4/libgcc/opt $ROOT_DIR
cp -r $BUILD_DIR/toolchain/ipkg-mips-3.4/libpthread/opt $ROOT_DIR

echo 'Adding busybox...'
cp -r $BUILD_DIR/busybox-*/ipkg-install/opt $ROOT_DIR

echo 'Adding iptables...'
cp -r $SCRIPT_DIR/../Entware/build_dir/target-mips_mips32r2_glibc-*/linux-mips-3.4/iptables-*/ipkg-mips-3.4/iptables/opt $ROOT_DIR

echo 'Adding Debian minimal...'
[ -f debian-jessie-mips_clean.tgz ] || wget http://ndm.zyxmon.org/binaries/debian/debian-jessie-mips_clean.tgz
[ -f debian-jessie-mips_clean.tgz ]
sudo tar -xz -C $ROOT_DIR/opt -f debian-jessie-mips_clean.tgz

# Set up Debian chroot
sudo sed -i 's|Port 65022|Port 222|g' $ROOT_DIR/opt/debian/etc/ssh/sshd_config
sudo touch $ROOT_DIR/opt/debian/chroot-services.list
sudo chmod 666 $ROOT_DIR/opt/debian/chroot-services.list
echo 'ssh' >> $ROOT_DIR/opt/debian/chroot-services.list
sudo mkdir $ROOT_DIR/opt/debian/opt/etc

# Set SourcesList, hostname & resolv.conf
sudo cat > $ROOT_DIR/opt/debian/etc/apt/sources.list <<EOF
deb http://ftp.debian.org/debian/ jessie main non-free contrib
#deb-src http://ftp.debian.org/debian/ jessie main non-free contrib
EOF

sudo echo 'debian_mips' > $ROOT_DIR/opt/debian/etc/hostname
sudo echo 'nameserver 8.8.8.8' > $ROOT_DIR/opt/debian/etc/resolv.conf

echo 'Adding start script...'
mkdir -p $ROOT_DIR/opt/etc
cp $SCRIPT_DIR/initrc $ROOT_DIR/opt/etc

echo 'Adding ndmq utility...'
sudo tar -xz -C $ROOT_DIR/opt/debian -f ndmq-mips.tgz

echo 'Packing installer...'
[ -f $INSTALLER ] && rm -f $INSTALLER

# The lower compression gives -10 secs while unpacking on Omni II
#sudo tar -czf $INSTALLER -C $ROOT_DIR/opt bin etc lib sbin debian
sudo tar -I 'gzip -1' -cf $INSTALLER -C $ROOT_DIR/opt bin etc lib sbin debian

# Removing temp folder
sudo rm -fr $ROOT_DIR

echo "Done! Plug in EXT2/3/4 formatted USB drive to Keenetic, put $INSTALLER into \"install\" folder via SAMBA or FTP and activate OPKG component via WebUI."