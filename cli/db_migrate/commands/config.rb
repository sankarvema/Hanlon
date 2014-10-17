

module ProjectHanlon::DbMigration
  class Command

    class Config < ProjectHanlon::DbMigration::Command

      def initialize(args)
        super(args)

        @hidden = false
        @display_name = "config"
        @description = "Get / set hanlon database migration configuration parameters"

      end

      def cmd_validate(args)
        puts "Validate #{self.class.name} command"
      end

      def cmd_exec(args)
        puts "Configuration command executed"
        db_migrate_config = ProjectHanlon::Config::DbMigrate.new
        config = JSON(db_migrate_config.to_json)

        puts "Default Hanlon Database migration config:".yellow
        print_yaml config

        return true
      end

      def cmd_help
        puts "Help #{self.class.name} command"
      end

      def cmd_error
        puts "Error for #{self.class.name} command"
      end

    end
  end
end