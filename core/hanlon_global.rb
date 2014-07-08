$config_file_path = "#{$app_root}/conf/hanlon_#{$app_type}.conf"
$logging_path = "#{$app_root}/log/project_hanlon.log"
$temp_path = "#{$app_root}/tmp"

require 'object'
require 'diagnostics/tracer'
require 'diagnostics/loader'

Diagnostics::Loader.check_module('object', 'ProjectHanlon::Objectxe')

require 'config'

module ProjectHanlon
  class Global
    def initialize

      if($app_type == "server")
        $config = ProjectHanlon::Config::Server.instance
      else
        $config = ProjectHanlon::Config::Client.instance
      end

    end
  end
  # Provide access to the global configuration for the project.
  #
  # This makes the global data available fairly uniformly to the project,
  # replacing the older mechanism of connecting to the database to access the
  # configuration object by coincidence, navigating through the
  # data abstraction.
  def self.config
    #if($app_type == "server")
    #  config = ProjectHanlon::Config::Server.instance
    #else
    #  config = ProjectHanlon::Config::Client.instance
    #end

    $config
  end
end

ProjectHanlon::Global.new

require "set"
require "version"
require "object"
require "utility"
require "logging/logger"
require "error"
require "data"
require "config"
require "node"
require "policy"
require "engine"
require "slice"
require "persist"
require "model"
require "tagging"
require "policies"
require "image_service"
require "broker"
require "config/server"
require "config/client"

require 'helpers/object_patch'