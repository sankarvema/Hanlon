Dir[File.dirname(__FILE__) + "/cmds/**/*.rb"].each do |file|
  require file
end

module ProjectHanlon::Migrate
  class Command

    attr_accessor :display_name, :description, :hidden, :cmd_map

    def initialize()

      @hidden = true        #set command to hidden by default

      @display_name = "not set"
      @description = "to be defined"

      @cmd_function = "nope"
      @cmd_map =
          [
              ["-h", "--help", "Display this help message", "no_more_args", "cmd_help"]
          ]
    end

    # Return the name of this slice - essentially, the final classname without
    # the leading hierarchy, in Ruby "filename" format rather than "classname"
    # format.  Not cached, because this is seldom used, and is never on the
    # hot path.
    def command_name
      self.class.name.
          split('::').
          last.
          scan(/[[:upper:]][[:lower:]]*/).
          join('_').
          downcase
    end

    def cmd_validate

      valid = false

      @cmd_function = "cmd_help"

      @cmd_map.each {|cmd|

        if cmd[0] == $global.args[0] or cmd[1] == $global.args[0]
          func = "#{cmd[3]}"
          if eval func
            @cmd_function = cmd[4]
            valid = true
            break
          end
        end
      }

      ProjectHanlon::Utility::Console.print_argument_error display_name, $global.args if !valid
      puts
      cmd_exec
    end

    def cmd_exec
      eval "#{@cmd_function}"
      true
    end

    def cmd_help
      puts "Help for <#{command_name}> command"
      puts
      @cmd_map.each {|cmd|
        cmd_string = "#{cmd[0]}, #{cmd[1]}"
        ProjectHanlon::Utility::Console.print_help_command_line cmd_string, cmd[2]
      }
    end

    def cmd_error
      puts "Error for #{command_name} command"
    end

    def no_more_args
      valid = true
      if $global.args.length > 1
        valid false
      end
      valid
    end

  end
end