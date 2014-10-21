

module ProjectHanlon::DbMigration
  class Command

    class Config < ProjectHanlon::DbMigration::Command

      allowed_switches = %w[ "-f" "-g" "-t" "-h" "--help"]
      cmd_function = "display_config"
      @config_cmds =  %w[ "-f" "-g" "-t" "-h" "--help"]

        # [
        #     ["-g", "--generate", "Generate a default config file", "no_more_args","generate_config"],
        #     ["-t", "--test", "Validate current configuration file for any issues", "no_more_args", "test_config"],
        #     ["-h", "--help", "Display this help message", "no_more_args", "display_help"]
        # ]

      def initialize(args=nil)
        super(args)

        @hidden = false
        @display_name = "config"
        @description = "Get / set hanlon database migration configuration parameters"

      end

      def cmd_validate(args)
        puts "Validate #{self.class.name} command with #{args[0]}"
        #print args

        valid = false
        cmd_function = "cmd_help"



        @config_cmds.each { |cmd| puts cmd}

        @config_cmds.all? {|cmd|

          puts "run command #{cmd}"
          if cmd.command == args[0] or cmd.alt_command == args[0]
            if eval "cmd.#{cmd.validator}"
              cmd_function = cmd.function
              valid = true
            end
          end
        }

        valid

      end

      def cmd_exec(args)
        puts "exec #{self.class.name} command with #{cmd_function}"

      end

      def generate_config
        puts "Configuration command executed"
        db_migrate_config = ProjectHanlon::Config::DbMigrate.new
        config = JSON(db_migrate_config.to_json)

        puts "Default Hanlon Database migration config:".yellow
        ProjectHanlon::Utility.print_yaml config

        return true
      end

      def cmd_help
        puts "Config help comes here..."
        puts
        puts "Invalid command or arguments".red if !valid
      end

      def cmd_error
        puts "Error for #{self.class.name} command"
      end

      def no_more_args

        valid = true;
        if args.length > 1
          valid false
        end

        valid

      end

    end
  end
end