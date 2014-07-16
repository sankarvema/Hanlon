#

# define an 'at_exit' handler; this handler is used to shut down the thread(s)
# that are used to run periodic tasks when the server is shut down or restarted
# (Note:  this handler needs to be defined here, before the "require 'grape'",
# below, is used to draw in Grape and it's dependencies)
at_exit { Hanlon::WebService::App.stop_periodic_tasks }

require "rubygems"
require "yaml"
require "grape"

# Load the application
require 'pathname'

$app_root = Pathname(__FILE__).realpath.dirname.to_s
$hanlon_root = Pathname(__FILE__).parent.realpath.dirname.to_s
$app_type = "server"

$LOAD_PATH.unshift((Pathname(__FILE__).realpath.dirname + '../util').cleanpath.to_s)
$LOAD_PATH.unshift((Pathname(__FILE__).realpath.dirname + '../core').cleanpath.to_s)
$LOAD_PATH.unshift((Pathname(__FILE__).realpath.dirname + './api').cleanpath.to_s)

#PROJECT_ROOT = Pathname(__FILE__).expand_path.parent.parent.to_s
#$LOAD_PATH.unshift(File.join(PROJECT_ROOT, "api"))
#$LOAD_PATH.unshift(File.join(PROJECT_ROOT, "app"))
#$LOAD_PATH.unshift(File.join(PROJECT_ROOT, "lib"))

require 'hanlon_global'

# hanlon dependencies
require 'object'
require 'slice'

# Load service config
#SERVICE_CONFIG = YAML.load_file(File.join(PROJECT_ROOT, "config/service.yaml"))
#SERVICE_CONFIG = YAML.load_file(File.join($app_root, "conf/service.yaml"))

# Define path to iPXE ERB file and a few iPXE-related parameters
# ToDo::Sankar::Refactor IPXE_ERB value to be changed to work on app servers

IPXE_ERB = File.join($app_root, "/config/hanlon.ipxe.erb")
IPXE_NIC_MAX = 7
IPXE_TIMEOUT = 15

# used in cases where the Hanlon server configuration does not have a
# parameter value for the daemon_min_cycle_time (defaults to a minute)
DEFAULT_MIN_CYCLE_TIME = 60

# used in cases where the Hanlon server configuration does not have a
# parameter value for the node_expire_timeout (uses a 10 minute default)
DEFAULT_NODE_EXPIRE_TIMEOUT = 60 * 10

require "./api/monkey_patch"
Dir.glob(File.join($app_root, "/api/api_*.rb")) do |f|
  next if f == "." || f == ".." || /\/api_utils.rb$/.match(f)
  require "./api/" + File.basename(f)
end

#ToDo::Sankar::Commented to check if it is really needed
Dir.glob(File.join($app_root, "/api/swagger*.rb")) do |f|
  next if f == "." || f == ".."
  require File.basename(f)
end

require "./app"
require "response"
