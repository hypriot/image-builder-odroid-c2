#!/bin/bash
set -ex

# This script should be run only inside of a Docker container
if [ ! -f /.dockerenv ]; then
  echo "ERROR: script works only in a Docker container!"
  exit 1
fi

# get versions for software that needs to be installed
# shellcheck disable=SC1091
source /workspace/versions.config

### setting up some important variables to control the build process

# where to store our created sd-image file
BUILD_RESULT_PATH="/workspace"

# place to build our sd-image
BUILD_PATH="/build"

ROOTFS_TAR="rootfs-arm64-debian-${HYPRIOT_OS_VERSION}.tar.gz"
ROOTFS_TAR_PATH="$BUILD_RESULT_PATH/$ROOTFS_TAR"

# Show TRAVSI_TAG in travis builds
echo TRAVIS_TAG="${TRAVIS_TAG}"

# name of the sd-image we gonna create
HYPRIOT_IMAGE_VERSION=${VERSION:="dirty"}
HYPRIOT_IMAGE_NAME="hypriotos-odroid-c2-${HYPRIOT_IMAGE_VERSION}.img"
QEMU_ARCH="aarch64"
export HYPRIOT_IMAGE_VERSION

# create build directory for assembling our image filesystem
rm -rf $BUILD_PATH
mkdir -p $BUILD_PATH

# download our base root file system
if [ ! -f "$ROOTFS_TAR_PATH" ]; then
  wget -q -O "$ROOTFS_TAR_PATH" "https://github.com/hypriot/os-rootfs/releases/download/$HYPRIOT_OS_VERSION/$ROOTFS_TAR"
fi

# verify checksum of our root filesystem
echo "${ROOTFS_TAR_CHECKSUM} ${ROOTFS_TAR_PATH}" | sha256sum -c -

# extract root file system
tar -xzf "$ROOTFS_TAR_PATH" -C $BUILD_PATH

# register qemu-arm with binfmt
# to ensure that binaries we use in the chroot
# are executed via qemu-arm
update-binfmts --enable qemu-$QEMU_ARCH

# set up mount points for pseudo filesystems
mkdir -p $BUILD_PATH/{proc,sys,dev/pts}

mount -o bind /dev $BUILD_PATH/dev
mount -o bind /dev/pts $BUILD_PATH/dev/pts
mount -t proc none $BUILD_PATH/proc
mount -t sysfs none $BUILD_PATH/sys

# modify/add image files directly
# e.g. root partition resize script
cp -R /builder/files/* $BUILD_PATH/

# make our build directory the current root
# and install the kernel packages, docker tools
# and some customizations for Odroid C2.
chroot $BUILD_PATH /bin/bash < /builder/chroot-script.sh

# unmount pseudo filesystems
umount -l $BUILD_PATH/sys
umount -l $BUILD_PATH/proc
umount -l $BUILD_PATH/dev/pts
umount -l $BUILD_PATH/dev

# package image filesytem into two tarballs - one for bootfs and one for rootfs
# ensure that there are no leftover artifacts in the pseudo filesystems
rm -rf ${BUILD_PATH}/{dev,sys,proc}/*

tar -czf /image_with_kernel_boot.tar.gz -C ${BUILD_PATH}/boot .
du -sh ${BUILD_PATH}/boot
rm -Rf ${BUILD_PATH}/boot
tar -czf /image_with_kernel_root.tar.gz -C ${BUILD_PATH} .
du -sh ${BUILD_PATH}
ls -alh /image_with_kernel_*.tar.gz

# download the ready-made raw image for the Odroid
if [ ! -f "${BUILD_RESULT_PATH}/${RAW_IMAGE}.zip" ]; then
  wget -q -O "${BUILD_RESULT_PATH}/${RAW_IMAGE}.zip" "https://github.com/hypriot/image-builder-raw/releases/download/${RAW_IMAGE_VERSION}/${RAW_IMAGE}.zip"
fi

# verify checksum of the ready-made raw image
echo "${RAW_IMAGE_CHECKSUM} ${BUILD_RESULT_PATH}/${RAW_IMAGE}.zip" | sha256sum -c -

unzip -p "${BUILD_RESULT_PATH}/${RAW_IMAGE}" > "/${HYPRIOT_IMAGE_NAME}"

# download current bootloader/u-boot images from hardkernel
wget -q -O - http://dn.odroid.com/S905/BootLoader/ODROID-C2/c2_boot_release_ubuntu.tar.gz | tar -C /tmp -xzvf -
cp /tmp/sd_fuse/bl1.bin.hardkernel .
cp /tmp/sd_fuse/u-boot.bin .
cp /tmp/sd_fuse/sd_fusing.sh .
rm -rf /tmp/sd_fuse/

export LIBGUESTFS_DEBUG=1 LIBGUESTFS_TRACE=1
guestfish -a "/${HYPRIOT_IMAGE_NAME}"
guestfish -a "/${HYPRIOT_IMAGE_NAME}" << _EOF_
  run

  # import filesystem content
  mount /dev/sda2 /
  tar-in /image_with_kernel_root.tar.gz / compress:gzip
  mkdir /boot
  mount /dev/sda1 /boot
  tar-in /image_with_kernel_boot.tar.gz /boot compress:gzip

  # write bootloader and u-boot into image start sectors 0-3071
  upload bl1.bin.hardkernel /boot/bl1.bin.hardkernel
  upload u-boot.bin /boot/u-boot.bin
  copy-file-to-device /boot/bl1.bin.hardkernel /dev/sda size:442 sparse:true
  copy-file-to-device /boot/bl1.bin.hardkernel /dev/sda srcoffset:512 destoffset:512 sparse:true
  copy-file-to-device /boot/u-boot.bin /dev/sda destoffset:49664 sparse:true
_EOF_

# ensure that the travis-ci user can access the SD card image file
umask 0000

# compress image
pigz --zip -c "${HYPRIOT_IMAGE_NAME}" > "${BUILD_RESULT_PATH}/${HYPRIOT_IMAGE_NAME}.zip"
cd ${BUILD_RESULT_PATH} && sha256sum "${HYPRIOT_IMAGE_NAME}.zip" > "${HYPRIOT_IMAGE_NAME}.zip.sha256" && cd -

# test sd-image that we have built
VERSION=${HYPRIOT_IMAGE_VERSION} rspec --format documentation --color /builder/test
