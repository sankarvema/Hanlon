

module ProjectHanlon::DbMigration
  class Command

    class Run < ProjectHanlon::DbMigration::Command

      def initialize(args)
        super(args)

        @hidden = false
        @display_name = "run"
        @description = "Performs migration of data from source to destination databases"

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