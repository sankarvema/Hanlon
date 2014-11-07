source = case ENV['INSTALL_MODE']
         when nil, '', 'git'      then 'git'
         when 'internal-packages' then 'package'
         else
           raise "unknown install mode '#{ENV['INSTALL_MODE']}"
         end

test_name "Install hanlon (with #{source})"

step "install hanlon"
mk_url = if ENV['INSTALL_MODE'] == 'internal-packages' then
           "http://neptune.puppetlabs.lan/dev/hanlon/iso/#{ENV['isobuild'] || 'current'}/#{ENV['mkflavour'] || 'prod'}/hanlon-microkernel-latest.iso"
         else
           "https://downloads.puppetlabs.com/hanlon/builds/iso/#{ENV['mkflavour'] || 'prod'}/hanlon-microkernel-latest.iso"
         end

on hosts('hanlon-server'), puppet_apply("--verbose"), :stdin => %Q'
class { sudo: config_file_replace => false }
class { hanlon: source => #{source}, username => hanlon, mk_source => "#{mk_url}" }
'

step "validate hanlon installation"
on hosts('hanlon-server'), "/opt/hanlon/bin/hanlon_daemon.rb status" do
  assert_match(/hanlon_daemon: running/, stdout)
end

step "copy the spec tests from git to the test host"
scp_to(hosts('hanlon-server'), "#{ENV['WORKSPACE']}/acceptance-spec", '/opt/hanlon')
