
module ProjectHanlon::DbMigration
  class Command

    class Config < ProjectHanlon::DbMigration::Command

      def initialize
        super

        @hidden = false
        @display_name = "config"
        @description = "Get / set hanlon database migration configuration parameters"

        @cmd_function = "display_config"
        @cmd_map =
        [
            ["-t", "--test", "Validate current configuration file for any issues", "no_more_args", "test_config"],
            ["-g", "--generate", "Generate a default config file", "no_more_args","generate_config"],
            ["-h", "--help", "Display this help message", "no_more_args", "cmd_help"]
        ]
      end

      def generate_config
        puts "Configuration command executed"
        db_migrate_config = ProjectHanlon::Config::DbMigrate.new
        config = JSON(db_migrate_config.to_json)

        puts "Default Hanlon Database migration config:".yellow
        ProjectHanlon::Utility.print_yaml config

        return true
      end

      def test_config
        puts "Configuration test executed"

        return true
      end

      def cmd_error
        puts "Error for #{self.class.name} command"
      end
    end
  end
end