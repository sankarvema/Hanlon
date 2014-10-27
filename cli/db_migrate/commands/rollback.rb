

module ProjectHanlon::DbMigration
  class Command

    class Rollback < ProjectHanlon::DbMigration::Command

      def initialize
        super

        @hidden = false
        @display_name = "rollback"
        @description = "Rollback a previous database migration"

      end

    end
  end
end