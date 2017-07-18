require 'spec_helper'

describe file('/boot/bl1.bin.hardkernel') do
  it { should be_file }
  it { should be_mode 755 }
  it { should be_owned_by 'root' }
end

describe file('/boot/boot.ini') do
  it { should be_file }
  it { should be_mode 755 }
  it { should be_owned_by 'root' }
end

describe file('/boot/meson64_odroidc2.dtb') do
  it { should be_file }
  it { should be_mode 755 }
  it { should be_owned_by 'root' }
end

describe file('/boot/u-boot.bin') do
  it { should be_file }
  it { should be_mode 755 }
  it { should be_owned_by 'root' }
end

describe file('/boot/device-init.yaml') do
  it { should_not be_file }
end
