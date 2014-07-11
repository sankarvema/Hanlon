require 'logger'

class Logger

  def add(severity, message = nil, progname = nil, &block)
    puts "Log add patched."

    @logdev = LogDevice.new($logging_path)

    severity ||= UNKNOWN
    if @logdev.nil? or severity < @level
      return true
    end
    progname ||= @progname
    if message.nil?
      if block_given?
        message = yield
      else
        message = progname
        progname = @progname
      end
    end
    @logdev.write(
        format_message(format_severity(severity), Time.now, progname, message))
    true
  end

end