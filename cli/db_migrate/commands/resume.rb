

module ProjectHanlon::DbMigration
  class Command

    class Resume < ProjectHanlon::DbMigration::Command

      def initialize(args)
        super(args)

        @hidden = false
        @display_name = "resume"
        @description = "Resumes a previously halted database migration"

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