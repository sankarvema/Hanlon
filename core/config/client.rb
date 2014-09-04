require 'socket'
require 'fcntl'
require 'yaml'
require 'utility'
require 'logging/logger'

require 'config/common'

# This class represents the ProjectHanlon cli configuration. It is stored persistently in
# './cli/config/hanlon_client.conf' and editing by the user

module ProjectHanlon
  module Config
    class Client
      include ProjectHanlon::Utility
      include ProjectHanlon::Logging
      include ProjectHanlon::Config::Common
      extend  ProjectHanlon::Logging

      attr_accessor :hanlon_server
      attr_accessor :base_path
      attr_accessor :api_version
      attr_accessor :api_port
      attr_accessor :admin_port

      attr_accessor :hanlon_log_level

      attr_reader   :noun

      # Obtain our defaults
      def defaults

        default_base_path = "/hanlon/api"
        default_image_path  = "#{$hanlon_root}/image"

        defaults = {
          'hanlon_server'            => get_an_ip,
          'base_path'                => default_base_path,
          'api_version'              => 'v1',
          'admin_port'               => 8025,
          'api_port'                 => 8026,

          'hanlon_log_level'        => "Logger::ERROR"
        }

        return defaults
      end

    end
  end
end
