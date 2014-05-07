require "logger"

# ToDo::Sankar::Implement log level hardcoded for time being
# this should come from config parameter {hanlon_log_level}
LOG_LEVEL = Logger::DEBUG
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
        @_logger.progname = "#{classname}\##{methodname}"
        puts "logger initialized #{@_logger.progname} with log level #{@_logger.level}"

        @_logger
      end

      # Singleton override that returns a logger for each specific instance
      class << self

        def get_log_path
          $logging_path
        end

        # ToDo::Sankar::Fix - ENV['HANLON_LOG_LEVEL'] to be replace with config parameter {hanlon_log_level}
        def get_log_level
          if ENV['HANLON_LOG_LEVEL'] == nil
            return LOG_LEVEL
          end
          ENV['HANLON_LOG_LEVEL'].to_i
        end

        # Returns specific logger instance from loggers[Hash] or creates one if it doesn't exist
        def logger_for(classname, methodname)
          @loggers[classname] ||= configure_logger_for(classname, methodname)
        end

        # Creates a logger instance
        def configure_logger_for(classname, methodname)
          logger = Logger.new(get_log_path, shift_age = LOG_MAX_FILES, shift_size = LOG_MAX_SIZE)
          logger.level = get_log_level
          logger
        end

        def log_exception(ex)
          logger.error "exception occured #{ex.message}"
          logger.debug "#{ex.backtrace}"
        end

      end

end
