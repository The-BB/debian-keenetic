#!/bin/sh

# Working dir should stay here
SCRIPT_DIR=$(dirname $0)

ROOT_DIR=$SCRIPT_DIR/installer_root
BUILD_DIR=$SCRIPT_DIR/../Entware-ng/build_dir/target-mipsel_mips32r2_uClibc-*
INSTALLER=$SCRIPT_DIR/debian-keenetic.tar.gz

# Compile libc and busybox from Entware-ng first!
[ -d $BUILD_DIR ] || exit 1

[ -d $ROOT_DIR ] && rm -fr $ROOT_DIR
mkdir $ROOT_DIR

# Adding toolchain libraries
cp -r $BUILD_DIR/toolchain/ipkg-mipselsf/libc/opt $ROOT_DIR

# Adding busybox
cp -r $BUILD_DIR/busybox-*/ipkg-install/opt $ROOT_DIR

# Adding Debian chroot
[ -f debian_clean.tgz ] || wget http://files.ryzhov-al.ru/Routers/chroot-debian/debian_clean.tgz
sudo tar -xz -C $ROOT_DIR/opt -f debian_clean.tgz

# Set up Debian chroot
sudo sed -i 's|Port 65022|Port 22|g' $ROOT_DIR/opt/debian/etc/ssh/sshd_config
sudo touch $ROOT_DIR/opt/debian/chroot-services.list
sudo chmod 666 $ROOT_DIR/opt/debian/chroot-services.list
echo 'ssh' >> $ROOT_DIR/opt/debian/chroot-services.list

# Adding start script
mkdir -p $ROOT_DIR/opt/etc
cp $SCRIPT_DIR/initrc $ROOT_DIR/opt/etc



# Packing installer
[ -f $INSTALLER ] && rm $INSTALLER

# The lower compression gives -10 secs while unpacking on Omni II
#sudo tar -czf $INSTALLER -C $ROOT_DIR/opt bin etc lib sbin debian
sudo tar -I 'gzip -1' -cf $INSTALLER -C $ROOT_DIR/opt  bin etc lib sbin debian

# Removing temp folder
sudo rm -fr $ROOT_DIR
