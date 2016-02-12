require 'spec_helper'

describe package('apt-transport-https') do
  it { should be_installed }
end

describe file('/etc/apt/sources.list.d/hypriot.list') do
  it { should be_file }
  it { should be_mode 644 }
  it { should be_owned_by 'root' }
  it { should contain 'deb https://packagecloud.io/Hypriot/Schatzkiste/debian/ wheezy main' }
end

describe file('/etc/apt/sources.list.d/odroid.list') do
  it { should be_file }
  it { should be_mode 644 }
  it { should be_owned_by 'root' }
  it { should contain 'deb http://deb.odroid.in/c2/ trusty main' }
  it { should contain 'deb http://deb.odroid.in/ trusty main' }
end
