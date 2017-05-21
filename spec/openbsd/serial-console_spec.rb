require 'spec_helper'

# Enabling serial and internal consoles
describe file('/etc/boot.conf') do
  it { should be_file }
  it { should contain "stty com0 38400" }
  it { should contain "set tty com0" }
end

describe file('/etc/ttys') do
  it { should be_file }
  it { should contain "tty00   \"/usr/libexec/getty std.38400\"   vt220 on secure" }
end
