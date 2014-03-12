require 'pathname'

test_name "Occam Server Performance Testing"

Occam = hosts('occam-server')

step "Flush the existing project_occam mongo database"
on Occam, "mongo project_occam --eval 'db.dropDatabase()'"

step "Restart the occam daemon"
on Occam, "/opt/occam/bin/occam_daemon.rb restart"

def add_image(args = {})
  what = args[:name] || args[:type]
  uuid = nil
  url  = args.delete(:url)
  iso  = "/tmp/#{what}.iso"
  args = args.map{|k, v| "--#{k} '#{v}'"}.join(' ')

  step "Fetch the #{what} ISO"
  on Occam, "curl -Lo #{iso} #{url}"

  step "Install the #{what} image"
  on Occam, "occam image add #{args} --path #{iso}" do
    match = /UUID => +([a-zA-Z0-9]+)$/.match(stdout) || []
    uuid  = match[1]
    if !uuid or uuid.length < 15
      fail_test("unable to match the #{what} UUID from Occam:\nmatch: #{match.inspect}\nuuid:  #{uuid.inspect}\nout:\n#{stdout}")
    end
  end

  step "Remove the ISO image"
  on Occam, "rm -f #{iso}"

  return uuid
end

step "Add OS images to Occam"
mk_url = if ENV['INSTALL_MODE'] == 'internal-packages' then
           "http://neptune.puppetlabs.lan/dev/occam/iso/#{ENV['isobuild'] || 'current'}/#{ENV['mkflavour'] || 'prod'}/occam-microkernel-latest.iso"
         else
           "https://downloads.puppetlabs.com/occam/builds/iso/#{ENV['mkflavour'] || 'prod'}/occam-microkernel-latest.iso"
         end

mk     = add_image(:type => 'mk', :url => mk_url)
esxi   = add_image(:type => 'esxi', :url => "http://int-resources.ops.puppetlabs.net/Software/VMware/VMware-VMvisor-Installer-5.0.0-469512.x86_64.iso")
ubuntu = add_image(:type => 'os', :name => 'ubuntu', :version => '1204', :url => "http://int-resources.ops.puppetlabs.net/ISO/Ubuntu/ubuntu-12.04-server-amd64.iso")

# The simulator doesn't have a CentOS / EL scenario yet, but we should add
# one fairly soon.  When you do:
#
# centos = add_image(:type => 'os', :name => 'centos', :version => '62', :url => "http://int-resources.ops.puppetlabs.net/ISO/CentOS/CentOS-6.2-x86_64-minimal.iso")


step "Upload the perftest tool source code"
source = (Pathname.new(__FILE__).dirname + "../perftest").cleanpath.to_s
on Occam, "rm -rf /tmp/perftest"
scp_to(Occam, source, "/tmp")

step "Install required packages to build"
on hosts('occam-server'), puppet_apply("--verbose"), :stdin => %q'
package { "build-essential":     ensure => installed }
package { "pkg-config":          ensure => installed }
package { "libglib2.0-dev":      ensure => installed }
package { "libcurl4-gnutls-dev": ensure => installed }
package { "liburiparser-dev":    ensure => installed }
package { "make":                ensure => installed }
'

step "Build perftest"
on Occam, "cd /tmp/perftest && make"

step "Ensure that Occam is running cleanly"
on Occam, "/opt/occam/bin/occam_daemon.rb stop"
on Occam, "/opt/occam/bin/occam_daemon.rb start"
on Occam, "service xinetd restart"

step "Running perftest suite"
on Occam, "cd /tmp/perftest && " +
  "./perftest --target=localhost " +
  "--esxi-uuid=#{esxi} --ubuntu-uuid=#{ubuntu} --mk-uuid=#{mk} " +
  "--load=10 --population=20000"

step "Fetch back performance results"
perf = Pathname('../perf')
perf.directory? and perf.rmtree

Occam.each do |host|
  dir = perf + host
  dir.mkpath

  on host, "ls /tmp/perftest/*.{csv,jtl}", :acceptable_exit_codes => 0..65535 do
    stdout.split("\n").each do |file|
      next if file.include? '/*.' # nothing matches
      scp_from(host, file, dir + Pathname(file).basename)
    end
  end
end
