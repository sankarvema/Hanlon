
module ProjectHanlon::DbMigration
  class Command

    class Run < ProjectHanlon::DbMigration::Command

      def initialize
        super

        @hidden = false
        @display_name = "run"
        @description = "Performs migration of data from source to destination databases"

        @cmd_map =
            [
                ["-t", "--test", "Perform a test or dry run of database migration", "no_more_args", "test_migration"],
                ["-h", "--help", "Display this help message", "no_more_args", "cmd_help"]
            ]

      end

      def test_migration

        migrate = ProjectHanlon::DbMigration::Controller.new
        migrate.test
      end

    end
  end
end