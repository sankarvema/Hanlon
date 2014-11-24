module ProjectHanlon::Utility
  module Console
    def self.print_argument_error(cmd, args)
      puts "Error executing command #{cmd}:".red

      if args == nil or args.empty?
        print "\tNo arguments specified for command ".white
        print "#{cmd}".bold.white
        print "\n"
      else
        print "\tInvalid arguments #{args} for command ".white
        print "#{cmd}".bold.white
        print "\n"
      end
    end

    def self.print_help_command_line(cmd, desc)
      print "    #{cmd.ljust(18)} ".bold.white
      print "#{desc}\n".yellow
    end
  end
end