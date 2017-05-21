require 'spec_helper'

# This test requires a VM to be provision with two IPs, preferably one public
# and one private.

# Test to ensure the VM has two interfaces, vio0 and vio1
describe interface('vio0') do
  it { should exist }
end

describe interface('vio1') do
  it { should exist }
end
