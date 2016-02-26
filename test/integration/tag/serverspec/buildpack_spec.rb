require "serverspec"

describe package("bash") do
  it { should be_installed }
end

describe package("git") do
  it { should be_installed }
end

describe file("/srv/app/current") do
  it { should be_directory }
end

describe file("/srv/app/current/activate") do
  it { should be_file }
  it { should contain "sudo -u root" }
end

describe file("/srv/app/current/.profile.d/ruby.sh") do
  it { should be_file }
end

describe file("/srv/app/current/bin/ruby") do
  it { should be_file }
end

describe command("/srv/app/current/activate -c 'ruby --version'") do
  its(:exit_status) { should eq 0 }
  its(:stdout) { should match 'ruby 2.3.0' }
end
