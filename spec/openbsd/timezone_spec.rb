require 'spec_helper'

describe command('date +%z') do
    its(:stdout) { should match /\+0000/ }
end
