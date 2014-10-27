module ProjectHanlon::DbMigration
  class Command

    attr_accessor :display_name, :description, :hidden, :config_cmds

    def initialize()

      @hidden = true        #set command to hidden by default

      @display_name = "not set"
      @description = "to be defined"

      @cmd_function = "nope"
      @config_cmds =
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

      puts "Validate #{self.class.name} command #{display_name} with #{$global.args[0]}"
      #print args

      valid = false
      #puts @cmd_function
      @cmd_function = "cmd_help"
      #puts @cmd_function

      #@config_cmds.each { |cmd| puts cmd}
      puts "config cmds...\n#{@config_cmds}"

      @config_cmds.each {|cmd|

        puts "run command #{cmd}"
        if cmd[0] == $global.args[0] or cmd[1] == $global.args[0]
          func = "#{cmd[3]}"
          puts "validation function to exec:: #{func}"
          #puts eval func
          if eval func
            @cmd_function = cmd[4]
            valid = true
            break
          end
        end
      }

      ProjectHanlon::Utility::Console.print_argument_error display_name, $global.args if !valid
      cmd_exec
    end

    def cmd_exec
      puts "exec #{self.class.name} command with #{@cmd_function}"

      eval "#{@cmd_function}"
      true
    end

    def cmd_help
      puts "Help for #{self.class.name} command"
      puts
      @config_cmds.each {|cmd|
        cmd_string = "#{cmd[0]}, #{cmd[1]}"
        ProjectHanlon::Utility::Console.print_help_command_line cmd_string, cmd[2]
      }
    end

    def cmd_error
      puts "Error for #{self.class.name} command"
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