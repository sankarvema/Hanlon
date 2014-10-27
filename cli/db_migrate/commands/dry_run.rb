

module ProjectHanlon::DbMigration
  class Command

    class Dryrun < ProjectHanlon::DbMigration::Command

      def initialize
        super

        @hidden = false
        @display_name = "dryrun"
        @description = "Performs a data dry run without actual object migration to destination database"

      end

    end
  end
end