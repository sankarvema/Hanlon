require 'colored'

module Diagnostics
  module Loader

    def self.check_module(file, mod)

      classname = self.class.name

      methodname = caller[0][/`([^']*)'/, 1]
      tracer_sign = "@@ #{caller[0]} from <class:#{classname}>\<method:#{methodname}>"

      puts "Diagnostics::Loader.check_module <file:#{file}, mod:#{mod}> -- #{tracer_sign}".green

      tracer_check = ">>>>> status :: "
      begin
        require file
        tracer_check += "[loaded==T] "
      rescue LoadError
        tracer_check += "[loaded==F] "
      end

      if defined?(mod)
        tracer_check += "[def==T] "
      else
        tracer_check += "[def==F] "
      end

      puts tracer_check

    end
  end

end




