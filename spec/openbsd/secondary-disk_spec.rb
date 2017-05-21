require 'spec_helper'

describe file('/data') do
  it { should be_directory }
  it { should be_mounted }
end
