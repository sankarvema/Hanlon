require "logger"
require "logging/logger_patch"

#custom_logger.rb
class CustomLogger < Logger
  # ToDo::Sankar:Implement - proper log formatting
  # current formating is through proxy logger def logger function
  #def format_message(severity, timestamp, progname, msg)
  #  "#{msg}\n"
  #end

  def log_exception(ex)
    self.error "exception occured #{ex.message}"
    self.error "#{ex.backtrace}"
  end
end