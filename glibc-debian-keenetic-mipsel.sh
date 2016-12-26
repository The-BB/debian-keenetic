#!/bin/sh

# Working dir should stay here
SCRIPT_DIR=$(dirname $0)

ROOT_DIR=$SCRIPT_DIR/installer_root
BUILD_DIR=$SCRIPT_DIR/../Entware-ng-3x/build_dir/target-mipsel_mips32r2_glibc-*
INSTALLER=$SCRIPT_DIR/debian-keenetic-mipsel.tar.gz

# Compile libc and busybox from Entware-ng-3x first!
[ -d $BUILD_DIR ] || exit 1

[ -d $ROOT_DIR ] && rm -fr $ROOT_DIR
# Make hook scripts dirs, see https://github.com/ndmsystems/packages/wiki/Opkg-Component
for dir in button fs netfilter schedule time usb user wan; do
    mkdir -p $ROOT_DIR/opt/etc/ndm/${dir}.d
done

echo 'Adding toolchain libraries...'
cp -r $BUILD_DIR/toolchain/ipkg-mipsel-3x/libc/opt $ROOT_DIR

echo 'Adding busybox...'
cp -r $BUILD_DIR/busybox-*/ipkg-install/opt $ROOT_DIR

echo 'Adding iptables...'
cp -r $SCRIPT_DIR/../Entware-ng-3x/build_dir/target-mipsel_mips32r2_glibc-*/linux-mipsel-3x/iptables-*/ipkg-mipsel-3x/iptables/opt $ROOT_DIR

echo 'Adding Debian minimal...'
[ -f debian_mipsel_clean.tgz ] || wget http://ndm.zyxmon.org/binaries/debian/debian_mipsel_clean.tgz
[ -f debian_mipsel_clean.tgz ]
sudo tar -xz -C $ROOT_DIR/opt -f debian_mipsel_clean.tgz

# Set up Debian chroot
sudo sed -i 's|Port 65022|Port 22|g' $ROOT_DIR/opt/debian/etc/ssh/sshd_config
sudo touch $ROOT_DIR/opt/debian/chroot-services.list
sudo chmod 666 $ROOT_DIR/opt/debian/chroot-services.list
echo 'ssh' >> $ROOT_DIR/opt/debian/chroot-services.list
sudo mkdir $ROOT_DIR/opt/debian/opt/etc

echo 'Adding start script...'
mkdir -p $ROOT_DIR/opt/etc
cp $SCRIPT_DIR/initrc $ROOT_DIR/opt/etc

echo 'Adding ndmq utility...'
sudo tar -xz -C $ROOT_DIR/opt/debian -f ndmq-mipsel.tgz

echo 'Packing installer...'
[ -f $INSTALLER ] && rm -f $INSTALLER

# The lower compression gives -10 secs while unpacking on Omni II
#sudo tar -czf $INSTALLER -C $ROOT_DIR/opt bin etc lib sbin debian
sudo tar -I 'gzip -1' -cf $INSTALLER -C $ROOT_DIR/opt  bin etc lib sbin debian

# Removing temp folder
sudo rm -fr $ROOT_DIR

echo "Done! Plug in EXT2/3/4 formatted USB drive to Keenetic, put $INSTALLER into \"install\" folder via SAMBA or FTP and activate OPKG component via WebUI."