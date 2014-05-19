require "logging/new_logger"
# ToDo::Sankar::Refactor
# refactor this file to logging/logger_proxy

# ToDo::Sankar::Implement log level hardcoded for time being
# this should come from config parameter {hanlon_log_level}

LOG_LEVEL = Logger::ERROR
LOG_MAX_SIZE = 10048576
LOG_MAX_FILES = 10

# Module used for all logging. Needs to be included in any ProjectHanlon class that needs logging.
# Uses Ruby Logger but overrides and instantiates one for each object that mixes in this module.
# It auto prefixes each log message with classname and method from which it was called using progname
module ProjectHanlon::Logging

      # [Hash] holds the loggers for each instance that includes it
      @loggers = {}

      # Returns the logger object specific to the instance that called it
      def logger
        classname = self.class.name
        methodname = caller[0][/`([^']*)'/, 1]

        @_logger ||= ProjectHanlon::Logging.logger_for(classname, methodname)
        @_logger.progname = "#{caller[0]}>>#{classname}\##{methodname}"

        @_logger
      end

      # Singleton override that returns a logger for each specific instance
      class << self

        def get_log_path

          if $logging_path.nil?
            "hanlon.log"
          else
            $logging_path
          end

        end

        # ToDo::Sankar::Fix - ENV['HANLON_LOG_LEVEL'] to be replace with config parameter {hanlon_log_level}
        def get_log_level
          return LOG_LEVEL
        end

        # Returns specific logger instance from loggers[Hash] or creates one if it doesn't exist
        def logger_for(classname, methodname)
          @loggers[classname] ||= configure_logger_for(classname, methodname)
        end

        require 'fileutils'
        # Creates a logger instance
        def configure_logger_for(classname, methodname)
          init_log
          logger = CustomLogger.new(get_log_path, shift_age = LOG_MAX_FILES, shift_size = LOG_MAX_SIZE)
          logger.level = get_log_level
          logger
        end

        #ToDo::Sankar::Workaround - this should be part of custom logger
        def init_log

          begin

            if !File.file?(get_log_path)

              FileUtils.mkdir_p(File.dirname(get_log_path))
              File.open(get_log_path, 'w') { |file| file.write("Log file initialized...") }

            end
          rescue Exception => e
            puts "exception occured @ logger.rb::init_log\n" + e.message.to_s + "\nException Stack Trace...\n" + e.backtrace.to_s
          end

        end

      end

end
