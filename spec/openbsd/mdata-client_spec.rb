require 'spec_helper'

# Ensure we have mdata-client tools installed

describe file('/usr/sbin/mdata-get') do
  it { should be_file }
  it { should be_executable }
end

describe file('/usr/sbin/mdata-put') do
  it { should be_file }
  it { should be_executable }
end

describe file('/usr/sbin/mdata-delete') do
  it { should be_file }
  it { should be_executable }
end

describe file('/usr/sbin/mdata-list') do
  it { should be_file }
  it { should be_executable }
end

## Test mdata client commands

# "root_authorized_keys" should always be there
describe command('mdata-get root_authorized_keys') do
  its(:exit_status) { should eq 0 }
end

# "derp" entry should not exist
describe command('mdata-get derp') do
  its(:exit_status) { should eq 1 }
  its(:stderr) { should match /No metadata for 'derp'/ }
end

# There should be at least one key, "root_authorized_keys"
describe command('mdata-list') do
  its(:exit_status) { should eq 0 }
  its(:stdout) { should match /root_authorized_keys/ }
end

# Create a test meta data key called "test"
describe command('mdata-put test test') do
  its(:exit_status) { should eq 0 }
end

# get meta data "test" key
describe command('mdata-get test') do
  its(:exit_status) { should eq 0 }
  its(:stdout) { should match /test/ }
end

#  "test" should be included in the list of metadata keys
describe command('mdata-list') do
  its(:exit_status) { should eq 0 }
  its(:stdout) { should match /root_authorized_keys/ }
  its(:stdout) { should match /test/ }
end

# delete "test" key
describe command('mdata-delete test') do
  its(:exit_status) { should eq 0 }
end

# "test" key is deleted, so should exit with 1 here 
describe command('mdata-get test') do
  its(:exit_status) { should eq 1 }
  its(:stderr) { should match /No metadata for 'test'/ }
end

