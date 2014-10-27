

module ProjectHanlon::DbMigration
  class Command

    class Resume < ProjectHanlon::DbMigration::Command

      def initialize
        super

        @hidden = false
        @display_name = "resume"
        @description = "Resumes a previously halted database migration"

      end

    end
  end
end