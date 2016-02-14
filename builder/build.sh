#!/bin/bash
set -ex
# This script should be run only inside of a Docker container
if [ ! -f /.dockerinit ]; then
  echo "ERROR: script works only in a Docker container!"
  exit 1
fi

### setting up some important variables to control the build process

# where to store our created sd-image file
BUILD_RESULT_PATH="/workspace"
BUILD_PATH="/build"

# where to store our base file system
HYPRIOT_OS_VERSION="v0.7.2"
ROOTFS_TAR="rootfs-arm64-${HYPRIOT_OS_VERSION}.tar.gz"
ROOTFS_TAR_PATH="$BUILD_RESULT_PATH/$ROOTFS_TAR"

# size of root and boot partion
ROOT_PARTITION_SIZE="800M"

# device specific settings
HYPRIOT_IMAGE_VERSION=${VERSION:="dirty"}
HYPRIOT_IMAGE_NAME="sd-card-odroid-c2-${HYPRIOT_IMAGE_VERSION}.img"
IMAGE_ROOTFS_PATH="/image-rootfs.tar.gz"
QEMU_ARCH="aarch64"
export HYPRIOT_IMAGE_VERSION

# specific versions of kernel/firmware and docker tools
export DOCKER_ENGINE_VERSION="1.9.1-1"
export DOCKER_COMPOSE_VERSION="1.5.2-80"
export DOCKER_MACHINE_VERSION="0.4.1-72"

# create build directory for assembling our image filesystem
rm -rf $BUILD_PATH
mkdir -p $BUILD_PATH

# download our base root file system
if [ ! -f $ROOTFS_TAR_PATH ]; then
  wget -q -O $ROOTFS_TAR_PATH https://github.com/hypriot/os-rootfs/releases/download/$HYPRIOT_OS_VERSION/$ROOTFS_TAR
fi

# extract root file system
tar -xzf $ROOTFS_TAR_PATH -C $BUILD_PATH

# register qemu-arm with binfmt
update-binfmts --enable qemu-$QEMU_ARCH

# set up mount points for pseudo filesystems
mkdir -p $BUILD_PATH/{proc,sys,dev/pts}

mount -o bind /dev $BUILD_PATH/dev
mount -o bind /dev/pts $BUILD_PATH/dev/pts
mount -t proc none $BUILD_PATH/proc
mount -t sysfs none $BUILD_PATH/sys

#---modify image---
# modify/add image files directly
cp -R /builder/files/* $BUILD_PATH/

# modify image in chroot environment
chroot $BUILD_PATH /bin/bash </builder/chroot-script.sh
#---modify image---

umount -l $BUILD_PATH/sys || true
umount -l $BUILD_PATH/proc || true
umount -l $BUILD_PATH/dev/pts || true
umount -l $BUILD_PATH/dev || true

# package image rootfs
tar -czf $IMAGE_ROOTFS_PATH -C $BUILD_PATH .

# create the image and add a single ext4 filesystem
# --- important settings for ODROID SD card
# - initialise the partion with MBR
# - use start sector 3072, this reserves 1.5MByte of disk space
# - don't set the partition to "bootable"
# - format the disk with ext4
# for debugging use 'set-verbose true'
#set-verbose true

#FIXME: use latest upstream u-boot files from hardkernel
# download current bootloader/u-boot images from hardkernel
wget -q -O - http://dn.odroid.com/S905/BootLoader/ODROID-C2/c2_bootloader.tar.gz | tar -C /tmp -xzvf -
cp /tmp/c2_bootloader/bl1.bin.hardkernel .
cp /tmp/c2_bootloader/u-boot.bin .
cp /tmp/c2_bootloader/sd_fusing.sh .
rm -rf /tmp/c2_bootloader/

guestfish <<EOF
# create new image disk
sparse /$HYPRIOT_IMAGE_NAME $ROOT_PARTITION_SIZE
run
part-init /dev/sda mbr
part-add /dev/sda primary 3072 -1
part-set-bootable /dev/sda 1 false
mkfs ext4 /dev/sda1

# import base rootfs
mount /dev/sda1 /
tar-in $IMAGE_ROOTFS_PATH / compress:gzip

#FIXME: use dd to directly writing u-boot to image file
#FIXME2: later on, create a dedicated .deb package to install/update u-boot
# write bootloader and u-boot into image start sectors 0-3071
upload sd_fusing.sh /boot/sd_fusing.sh
upload bl1.bin.hardkernel /boot/bl1.bin.hardkernel
upload u-boot.bin /boot/u-boot.bin
upload /builder/boot.ini /boot/boot.ini
copy-file-to-device /boot/bl1.bin.hardkernel /dev/sda size:442 sparse:true
copy-file-to-device /boot/bl1.bin.hardkernel /dev/sda srcoffset:512 destoffset:512 sparse:true
copy-file-to-device /boot/u-boot.bin /dev/sda destoffset:49664 sparse:true
EOF

# log image partioning
fdisk -l "/$HYPRIOT_IMAGE_NAME"

# ensure that the travis-ci user can access the SD card image file
umask 0000

# compress image
pigz --zip -c "$HYPRIOT_IMAGE_NAME" > "$BUILD_RESULT_PATH/$HYPRIOT_IMAGE_NAME.zip"

# test sd-image that we have built
VERSION=${HYPRIOT_IMAGE_VERSION} rspec --format documentation --color /builder/test
