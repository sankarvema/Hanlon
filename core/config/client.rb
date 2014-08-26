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
      attr_accessor :register_timeout

      attr_accessor :image_path

      attr_accessor :persist_mode
      attr_accessor :persist_host
      attr_accessor :persist_port
      attr_accessor :persist_username
      attr_accessor :persist_password
      attr_accessor :persist_timeout

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

          'register_timeout'         => 120,

          'image_path'               => default_image_path,
          'hanlon_log_level'        => "Logger::ERROR",
          'persist_mode'             => :mongo,
          'persist_host'             => "127.0.0.1",
          'persist_port'             => 27017,
          'persist_username'         => '',
          'persist_password'         => '',
          'persist_timeout'          => 10
        }

        return defaults
      end

    end
  end
end
