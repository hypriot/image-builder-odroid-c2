#!/bin/bash
set -ex

# save HYPRIOT_* content from /etc/os-release. Needs to be done in
# case base-files gets updated during build
< /etc/os-release grep HYPRIOT_ > /tmp/os-release.add

KEYSERVER="ha.pool.sks-keyservers.net"

function clean_print(){
  local fingerprint="${2}"
  local func="${1}"

  nospaces=${fingerprint//[:space:]/}
  tolowercase=${nospaces,,}
  KEYID_long=${tolowercase:(-16)}
  KEYID_short=${tolowercase:(-8)}
  if [[ "${func}" == "fpr" ]]; then
    echo "${tolowercase}"
  elif [[ "${func}" == "long" ]]; then
    echo "${KEYID_long}"
  elif [[ "${func}" == "short" ]]; then
    echo "${KEYID_short}"
  elif [[ "${func}" == "print" ]]; then
    if [[ "${fingerprint}" != "${nospaces}" ]]; then
      printf "%-10s %50s\n" fpr: "${fingerprint}"
    fi
    # if [[ "${nospaces}" != "${tolowercase}" ]]; then
    #   printf "%-10s %50s\n" nospaces: $nospaces
    # fi
    if [[ "${tolowercase}" != "${KEYID_long}" ]]; then
      printf "%-10s %50s\n" lower: "${tolowercase}"
    fi
    printf "%-10s %50s\n" long: "${KEYID_long}"
    printf "%-10s %50s\n" short: "${KEYID_short}"
    echo ""
  else
    echo "usage: function {print|fpr|long|short} GPGKEY"
  fi
}


function try_apt_key(){
    counter=0;
    status=0;

    while [[ $counter -lt 5 && status -ne 0 ]]; do
        apt-key adv --keyserver "$1" --recv-keys "$2" || status=$?
        counter+=1

        if [[ $status -ne 0 ]]; then
            sleep 1
        fi
    done
    
    return $status
}


function get_gpg(){
  GPG_KEY="${1}"
  KEY_URL="${2}"

  clean_print print "${GPG_KEY}"
  GPG_KEY=$(clean_print fpr "${GPG_KEY}")

  if [[ "${KEY_URL}" =~ ^https?://* ]]; then
    echo "loading key from url"
    KEY_FILE=temp.gpg.key
    wget -q -O "${KEY_FILE}" "${KEY_URL}"
  elif [[ -z "${KEY_URL}" ]]; then
    echo "no source given try to load from key server"
#    gpg --keyserver "${KEYSERVER}" --recv-keys "${GPG_KEY}"
    try_apt_key "${KEYSERVER}" "${GPG_KEY}"
    return $?
  else
    echo "keyfile given"
    KEY_FILE="${KEY_URL}"
  fi

  FINGERPRINT_OF_FILE=$(gpg --with-fingerprint --with-colons "${KEY_FILE}" | grep fpr | rev |cut -d: -f2 | rev)

  if [[ ${#GPG_KEY} -eq 16 ]]; then
    echo "compare long keyid"
    CHECK=$(clean_print long "${FINGERPRINT_OF_FILE}")
  elif [[ ${#GPG_KEY} -eq 8 ]]; then
    echo "compare short keyid"
    CHECK=$(clean_print short "${FINGERPRINT_OF_FILE}")
  else
    echo "compare fingerprint"
    CHECK=$(clean_print fpr "${FINGERPRINT_OF_FILE}")
  fi

  if [[ "${GPG_KEY}" == "${CHECK}" ]]; then
    echo "key OK add to apt"
    apt-key add "${KEY_FILE}"
    rm -f "${KEY_FILE}"
    return 0
  else
    echo "key invalid"
    exit 1
  fi
}


## examples:
# clean_print {print|fpr|long|short} {GPGKEYID|FINGERPRINT}
# get_gpg {GPGKEYID|FINGERPRINT} [URL|FILE]

# device specific settings
HYPRIOT_DEVICE="ODROID C2"

# set up /etc/resolv.conf
DEST=$(readlink -m /etc/resolv.conf)
export DEST
mkdir -p "$(dirname "${DEST}")"
echo "nameserver 8.8.8.8" > "${DEST}"

# Install the dirmngr for GPG usage
apt-get update
apt-get install dirmngr

# set up Docker CE repository
DOCKERREPO_FPR=9DC858229FC7DD38854AE2D88D81803C0EBFCD88
DOCKERREPO_KEY_URL=https://download.docker.com/linux/debian/gpg
get_gpg "${DOCKERREPO_FPR}" "${DOCKERREPO_KEY_URL}"

CHANNEL=edge # stable, test or edge
echo "deb [arch=arm64] https://download.docker.com/linux/debian stretch $CHANNEL" > /etc/apt/sources.list.d/docker.list

# set up debian jessie backports
echo "deb http://httpredir.debian.org/debian stretch-backports main" > /etc/apt/sources.list.d/stretch-backports.list

# set up ODROID repository
ODROID_KEY_ID=AB19BAC9
get_gpg $ODROID_KEY_ID
echo "deb http://deb.odroid.in/c2/ xenial main" > /etc/apt/sources.list.d/odroid.list

# add armhf as additional architecure (see below)
dpkg --add-architecture arm64

# update all apt repository lists
export DEBIAN_FRONTEND=noninteractive
apt-get update
apt-get upgrade -y

# define packages to install
packages=(
    # as the Odroid C2 does not have a hardware clock we need a fake one
    fake-hwclock

    # install dependencies for docker-tools
    lxc
    aufs-tools
    cgroupfs-mount
    cgroup-bin
    apparmor
    libseccomp2
    libltdl7

    # required to install docker-compose
    python-pip
    python-setuptools
    python-wheel
)

apt-get -y install --no-install-recommends "${packages[@]}"

# install docker-engine
apt-get install -y --force-yes \
    --no-install-recommends \
    "docker-ce=${DOCKER_CE_VERSION}"

# install docker-compose
pip install docker-compose=="${DOCKER_COMPOSE_VERSION}"

# install docker-machine
curl -L "https://github.com/docker/machine/releases/download/v${DOCKER_MACHINE_VERSION}/docker-machine-$(uname -s)-$(uname -m)" > /usr/local/bin/docker-machine
chmod +x /usr/local/bin/docker-machine

# install linux kernel for Odroid C2
apt-get -y install \
    --no-install-recommends \
    u-boot-tools \
    "linux-image-${KERNEL_VERSION}"

# Restore os-release additions
cat /tmp/os-release.add >> /etc/os-release

# cleanup APT cache and lists
apt-get clean
rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# set device label and version number
echo "HYPRIOT_DEVICE=\"$HYPRIOT_DEVICE\"" >> /etc/os-release
echo "HYPRIOT_IMAGE_VERSION=\"$HYPRIOT_IMAGE_VERSION\"" >> /etc/os-release
cp /etc/os-release /boot/os-release
