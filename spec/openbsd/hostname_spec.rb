require 'spec_helper'

describe command('hostname') do
  its(:exit_status) { should eq 0 }
end

