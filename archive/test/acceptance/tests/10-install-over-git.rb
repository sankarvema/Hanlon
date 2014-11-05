test_name "Install packages over git"
if ENV['INSTALL_MODE'] == 'git' then
  skip_test "We don't test `install over git` unless we are testing packages"
end

occam = hosts('occam-server')

step "Ensure that the package is not installed"
on occam, puppet_resource('package', 'puppet-occam', 'ensure=absent') do
  if stdout =~ /Error/i or stderr =~ /Error/i then
    fail_test("I guess an error happened during the ensure=absent run, maybe?")
  end
end

step "Ensure that the Occam directory is not present"
on occam, "test -e /opt/occam && rm -rf /opt/occam || :"

teardown do
  step "Remove that stub directory"
  # Right now this always returns zero, but tomorrow we might need to fix it
  # to respect a decent exit code. --daniel 2013-01-28
  on occam, puppet_resource('package', 'puppet-occam', 'ensure=absent')
  on occam, "test -e /opt/occam && rm -rf /opt/occam || :"
end

# I wish this could be less intrusive, but there really isn't any other
# option; while installation is still so full of random "install from
# upstream" bits, we have to run the full module to get a sane install.
step "install occam from git"
mk_url = if ENV['INSTALL_MODE'] == 'internal-packages' then
           "http://neptune.puppetlabs.lan/dev/occam/iso/#{ENV['isobuild'] || 'current'}/#{ENV['mkflavour'] || 'prod'}/occam-microkernel-latest.iso"
         else
           "https://downloads.puppetlabs.com/occam/builds/iso/#{ENV['mkflavour'] || 'prod'}/occam-microkernel-latest.iso"
         end

on hosts('occam-server'), puppet_apply("--verbose"), :stdin => %Q'
class { sudo: config_file_replace => false }
class { occam: source => git, username => occam, mk_source => "#{mk_url}" }
'

step "Ensure we fail to install the package!"
# This doesn't check for exit codes, only error messages, because
# in 3.0.2 ralsh kinda sucks: http://projects.puppetlabs.com/issues/18937
# --daniel 2013-01-28
on occam, puppet_resource('package', 'puppet-occam', 'ensure=latest') do
  unless (stdout + stderr) =~ /ensure => '(absent|purged)'/ then
    fail_test("I guess maybe we installed something when we shouldn't have, maybe?")
  end
end
