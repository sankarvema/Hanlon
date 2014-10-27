

module ProjectHanlon::DbMigration
  class Command

    class Status < ProjectHanlon::DbMigration::Command

      def initialize
        super

        @hidden = false
        @display_name = "status"
        @description = "Check the status of last migration"

      end

    end
  end
end