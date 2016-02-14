#!/bin/bash
set -ex

# device specific settings
HYPRIOT_DEVICE="ODROID C2"

# set up /etc/resolv.conf
echo "nameserver 8.8.8.8" > /etc/resolv.conf

# set up ODROID repository
apt-key adv --keyserver keyserver.ubuntu.com --recv-keys AB19BAC9
echo "deb http://deb.odroid.in/c2/ xenial main" > /etc/apt/sources.list.d/odroid.list

# # set up Hypriot Schatzkiste repository
# wget -q https://packagecloud.io/gpg.key -O - | apt-key add -
# echo 'deb https://packagecloud.io/Hypriot/Schatzkiste/debian/ wheezy main' > /etc/apt/sources.list.d/hypriot.list

# update all apt repository lists
export DEBIAN_FRONTEND=noninteractive
apt-get update

# ---install Docker tools---

# # install Hypriot packages for using Docker
# apt-get install -y \
#   "docker-hypriot=${DOCKER_ENGINE_VERSION}" \
#   "docker-compose=${DOCKER_COMPOSE_VERSION}" \
#   "docker-machine=${DOCKER_MACHINE_VERSION}"

# #FIXME: should be handled in .deb package
# # setup Docker default configuration for ODROID C2
# rm -f /etc/init.d/docker # we're using a pure systemd init, remove sysvinit script
# rm -f /etc/default/docker
# # --get upstream config
# wget -q -O /etc/default/docker https://github.com/docker/docker/raw/master/contrib/init/sysvinit-debian/docker.default
# # --enable aufs by default
# sed -i "/#DOCKER_OPTS/a \
# DOCKER_OPTS=\"--storage-driver=aufs -D\"" /etc/default/docker

# #FIXME: should be handled in .deb package
# # enable Docker systemd service
# systemctl enable docker

# install ODROID kernel

apt-get install -y u-boot-tools initramfs-tools

# make the kernel package create a copy of the current kernel here
touch /boot/uImage
apt-get install -y linux-image-c2 bootini

# set device label and version number
echo "HYPRIOT_DEVICE=\"$HYPRIOT_DEVICE\"" >> /etc/os-release
echo "HYPRIOT_IMAGE_VERSION=\"$HYPRIOT_IMAGE_VERSION\"" >> /etc/os-release
