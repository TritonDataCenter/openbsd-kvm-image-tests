require 'spec_helper'

describe file('/var/tmp/mdata-user-script') do
  it { should be_file }
  it { should be_owned_by 'root' }
  it { should be_executable }
end

describe file('/var/tmp/test') do
  it { should be_file }
end
