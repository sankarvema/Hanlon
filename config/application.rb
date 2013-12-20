#

require "rubygems"
require "yaml"
require "grape"
# Load the application
require 'pathname'
project_root = Pathname(__FILE__).expand_path.parent.parent.to_s
$LOAD_PATH.unshift(File.join(project_root, "api"))
$LOAD_PATH.unshift(File.join(project_root, "app"))
$LOAD_PATH.unshift(File.join(project_root, "lib"))

# razor dependencies
require 'project_razor/object'
require 'project_razor/slice'

# Load service config
SERVICE_CONFIG = YAML.load_file(File.join(project_root, "config/service.yaml"))

require "monkey_patch"
Dir.glob(File.join(project_root, "/api/api_*.rb")) do |f|
  next if f == "." || f == ".."
  require File.basename(f)
end

Dir.glob(File.join(project_root, "/api/swagger*.rb")) do |f|
  next if f == "." || f == ".."
  require File.basename(f)
end

require "api"
require "app"
require "response"
