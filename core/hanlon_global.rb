$config_file_path = "#{$app_root}/conf/hanlon_#{$app_type}.conf"
$logging_path = "#{$app_root}/log/project_hanlon.log"
$temp_path = "#{$app_root}/tmp"

require 'object'
require 'diagnostics/tracer'
require 'diagnostics/loader'
#
puts "\nCheck at hanlon_global\n"
#begin
#  require 'object'
#  puts "  base class object loaded successfully"
#rescue LoadError
#  puts "  error loading base class object"
#end
#
#if defined?(ProjectHanlon::Object)
#  puts "  base class object defined properly"
#else
#  puts "  base class object un-defined"
#end
#puts "}\n"

Diagnostics::Loader.check_module('object', 'ProjectHanlon::Objectxe')

require 'config'


module ProjectHanlon
  class Global
    def initialize
      puts "App type:: #{$app_type}"
      if($app_type == "server")
        $config = ProjectHanlon::Config::Server.instance
      else
        $config = ProjectHanlon::Config::Client.instance
      end
      puts "Config init @hanlon_global >>> #{$config.hanlon_uri + $config.websvc_root}"
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

    puts "Config init #{$config.hanlon_uri + $config.websvc_root}"
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