#

# define an 'at_exit' handler; this handler is used to shut down the thread(s)
# that are used to run periodic tasks when the server is shut down or restarted
# (Note:  this handler needs to be defined here, before the "require 'grape'",
# below, is used to draw in Grape and it's dependencies)
at_exit { Razor::WebService::App.stop_periodic_tasks }

require "rubygems"
require "yaml"
require "grape"
# Load the application
require 'pathname'
PROJECT_ROOT = Pathname(__FILE__).expand_path.parent.parent.to_s
$LOAD_PATH.unshift(File.join(PROJECT_ROOT, "api"))
$LOAD_PATH.unshift(File.join(PROJECT_ROOT, "app"))
$LOAD_PATH.unshift(File.join(PROJECT_ROOT, "lib"))

# razor dependencies
require 'project_razor/object'
require 'project_razor/slice'

# Load service config
SERVICE_CONFIG = YAML.load_file(File.join(PROJECT_ROOT, "config/service.yaml"))

# Define path to iPXE ERB file and a few iPXE-related parameters
IPXE_ERB = File.join(PROJECT_ROOT, "lib/project_razor/slice/config/razor.ipxe.erb")
IPXE_NIC_MAX = 7
IPXE_TIMEOUT = 15

# used in cases where the Razor server configuration does not have a
# parameter value for the daemon_min_cycle_time (defaults to a minute)
DEFAULT_MIN_CYCLE_TIME = 60

# used in cases where the Razor server configuration does not have a
# parameter value for the node_expire_timeout (uses a 10 minute default)
DEFAULT_NODE_EXPIRE_TIMEOUT = 60 * 10

require "monkey_patch"
Dir.glob(File.join(PROJECT_ROOT, "/api/api_*.rb")) do |f|
  next if f == "." || f == ".." || /\/api_utils.rb$/.match(f)
  require File.basename(f)
end

Dir.glob(File.join(PROJECT_ROOT, "/api/swagger*.rb")) do |f|
  next if f == "." || f == ".."
  require File.basename(f)
end

require "api"
require "app"
require "response"
