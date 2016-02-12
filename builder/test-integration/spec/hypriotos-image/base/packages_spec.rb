require 'spec_helper'

# rootfs packages
describe package('apt-transport-https') do
  it { should be_installed }
end
describe package('avahi-daemon') do
  it { should be_installed }
end
describe package('bash-completion') do
  it { should be_installed }
end
describe package('binutils') do
  it { should be_installed }
end
describe package('ca-certificates') do
  it { should be_installed }
end
describe package('curl') do
  it { should be_installed }
end
describe package('git-core') do
  it { should be_installed }
end
describe package('htop') do
  it { should be_installed }
end
describe package('locales') do
  it { should be_installed }
end
describe package('net-tools') do
  it { should be_installed }
end
describe package('openssh-server') do
  it { should be_installed }
end
describe package('parted') do
  it { should be_installed }
end
describe package('sudo') do
  it { should be_installed }
end
describe package('usbutils') do
  it { should be_installed }
end

# additional kernel packages
describe package('u-boot-tools') do
  it { should be_installed }
end
describe package('initramfs-tools') do
  it { should be_installed }
end
describe package('linux-image-c2') do
  it { should be_installed }
end

# additional application packages
describe package('docker-hypriot') do
  it { should be_installed }
end
describe package('docker-compose') do
  it { should be_installed }
end
describe package('docker-machine') do
  it { should be_installed }
end
