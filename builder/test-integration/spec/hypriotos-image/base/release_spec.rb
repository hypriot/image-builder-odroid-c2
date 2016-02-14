require 'spec_helper'

describe file('/etc/os-release') do
  it { should be_file }
  it { should be_owned_by 'root' }
  its(:content) { should match 'HYPRIOT_OS="HypriotOS/arm64"' }
  its(:content) { should match 'HYPRIOT_OS_VERSION="v0.7.2"' }
  its(:content) { should match 'HYPRIOT_DEVICE="ODROID C2"' }
  its(:content) { should match 'HYPRIOT_IMAGE_VERSION=' }
end
