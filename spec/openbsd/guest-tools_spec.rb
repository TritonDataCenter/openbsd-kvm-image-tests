require 'spec_helper'

# Ensure guest tools are installed in /lib/smartdc

describe file('/lib/smartdc/add-network-interface') do
  it { should be_file }
  it { should be_executable }
end

describe file('/lib/smartdc/firstboot') do
  it { should be_file }
  it { should be_executable }
end

describe file('/lib/smartdc/format-secondary-disk') do
  it { should be_file }
  it { should be_executable }
end

describe file('/lib/smartdc/common.lib') do
  it { should be_file }
  it { should be_executable }
end

describe file('/lib/smartdc/run-operator-script') do
  it { should be_file }
  it { should be_executable }
end

describe file('/lib/smartdc/run-user-script') do
  it { should be_file }
  it { should be_executable }
end

describe file('/lib/smartdc/set-hostname') do
  it { should be_file }
  it { should be_executable }
end

describe file('/lib/smartdc/set-root-authorized-keys') do
  it { should be_file }
  it { should be_executable }
end

describe file('/lib/smartdc/set-rootpassword') do
  it { should be_file }
  it { should be_executable }
end
