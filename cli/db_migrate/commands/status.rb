

module ProjectHanlon::DbMigration
  class Command

    class Status < ProjectHanlon::DbMigration::Command

      def initialize(args)
        super(args)

        @hidden = false
        @display_name = "status"
        @description = "Check the status of last migration"

      end

      def cmd_validate(args)
        puts "Validate #{self.class.name} command"
      end

      def cmd_exec(args)
        puts "Execute #{self.class.name} command"
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