describe file('/boot/boot.ini') do
  it { should be_file }
  it { should be_mode 755 }
  it { should be_owned_by 'root' }
  its(:content) { should match /root=\/dev\/mmcblk0p2/ }
  its(:content) { should match /rootfstype=ext4/ }
  its(:content) { should match /cgroup_enable=memory/ }
  its(:content) { should match /cgroup_enable=cpuset/ }
  its(:content) { should match /swapaccount=1/ }
  its(:content) { should match /elevator=deadline/ }
  its(:content) { should match /fsck.repair=yes/ }
  its(:content) { should match /rootwait/ }
end
