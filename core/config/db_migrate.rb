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
    class DbMigrate
      include ProjectHanlon::Utility
      include ProjectHanlon::Logging
      include ProjectHanlon::Config::Common
      extend  ProjectHanlon::Logging

      attr_accessor :source_persist_mode
      attr_accessor :source_persist_host
      attr_accessor :source_persist_port
      attr_accessor :source_persist_username
      attr_accessor :source_persist_password
      attr_accessor :source_persist_timeout
      attr_accessor :source_persist_dbname

      attr_accessor :destination_persist_mode
      attr_accessor :destination_persist_host
      attr_accessor :destination_persist_port
      attr_accessor :destination_persist_username
      attr_accessor :destination_persist_password
      attr_accessor :destination_persist_timeout
      attr_accessor :destination_persist_dbname

      attr_accessor :hanlon_log_level

      # Obtain our defaults
      def defaults

        defaults = {
            'source_persist_mode'                   => :mongo,
            'source_persist_host'                   => "127.0.0.1",
            'source_persist_port'                   => 27017,
            'source_persist_username'               => '',
            'source_persist_password'               => '',
            'source_persist_timeout'                => 10,
            'source_persist_dbname'                 => "project_hanlon_source",

            'destination_persist_mode'              => :mongo,
            'destination_persist_host'              => "127.0.0.1",
            'destination_persist_port'              => 27017,
            'destination_persist_username'          => '',
            'destination_persist_password'          => '',
            'destination_persist_timeout'           => 10,
            'destination_persist_dbname'            => "project_hanlon_destination",

            'hanlon_log_level'                      => "Logger::ERROR"
        }

        return defaults
      end

    end
  end
end
