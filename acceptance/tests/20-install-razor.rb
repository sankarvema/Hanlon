source = case ENV['INSTALL_MODE']
         when nil, '', 'git'      then 'git'
         when 'internal-packages' then 'package'
         else
           raise "unknown install mode '#{ENV['INSTALL_MODE']}"
         end

test_name "Install occam (with #{source})"

step "install occam"
mk_url = if ENV['INSTALL_MODE'] == 'internal-packages' then
           "http://neptune.puppetlabs.lan/dev/occam/iso/#{ENV['isobuild'] || 'current'}/#{ENV['mkflavour'] || 'prod'}/occam-microkernel-latest.iso"
         else
           "https://downloads.puppetlabs.com/occam/builds/iso/#{ENV['mkflavour'] || 'prod'}/occam-microkernel-latest.iso"
         end

on hosts('occam-server'), puppet_apply("--verbose"), :stdin => %Q'
class { sudo: config_file_replace => false }
class { occam: source => #{source}, username => occam, mk_source => "#{mk_url}" }
'

step "validate occam installation"
on hosts('occam-server'), "/opt/occam/bin/occam_daemon.rb status" do
  assert_match(/occam_daemon: running/, stdout)
end

step "copy the spec tests from git to the test host"
scp_to(hosts('occam-server'), "#{ENV['WORKSPACE']}/acceptance-spec", '/opt/occam')
