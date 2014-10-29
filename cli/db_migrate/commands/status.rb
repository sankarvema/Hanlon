

module ProjectHanlon::DbMigration
  class Command

    class Status < ProjectHanlon::DbMigration::Command

      def initialize
        super

        @hidden = false
        @display_name = "status"
        @description = "Check the stat us of last migration"

      end

    end
  end
end