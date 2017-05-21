require 'spec_helper'

# Tests to validate network and interfaces are properly configured 

describe host('google.com') do
  it { should be_resolvable }
end

describe file('/etc/resolv.conf') do
  it { should be_file }
	it { should contain "nameserver 8.8.8.8" }
	it { should contain "nameserver 8.8.4.4" }
end

