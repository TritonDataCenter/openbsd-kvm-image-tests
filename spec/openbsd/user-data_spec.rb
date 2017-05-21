require 'spec_helper'

# Test for user-data. This needs to be set on the test VM.
describe file('/var/tmp/mdata-user-data') do
  it { should be_file }
  it { should_not be_executable }
  it { should be_owned_by 'root' }
end
