require 'serverspec'
require 'net/ssh'
require 'yaml'

properties = YAML.load_file('properties.yml')

set :backend, :ssh


if ENV['ASK_SUDO_PASSWORD']
  begin
    require 'highline/import'
  rescue LoadError
    fail "highline is not available. Try installing it."
  end
  set :sudo_password, ask("Enter sudo password: ") { |q| q.echo = false }
else
  set :sudo_password, ENV['SUDO_PASSWORD']
end

host = ENV['TARGET_HOST']
set_property properties[host]

options = Net::SSH::Config.for(host)

set :host,        options[:host_name] || host

# Get HostName and User value from Env Vars if available
# This will override options in ~/.ssh/config or /etc/ssh_config
options[:host_name] ||= ENV['TARGET_HOST_NAME']
options[:user] ||= ENV['TARGET_USER_NAME']

set :ssh_options, options

# Don't save hosts to ~/.ssh/known_hosts
# When testing it's very common for the IPs to get reused and cause a mismatch
set :user_known_hosts_file, '/dev/null'
