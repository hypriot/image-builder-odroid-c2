require 'spec_helper'

Specinfra::Runner.run_command('modprobe btrfs')
describe kernel_module('btrfs') do
  it { should be_loaded }
end
