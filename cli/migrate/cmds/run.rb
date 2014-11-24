
module ProjectHanlon::Migrate
  class Command

    class Run < ProjectHanlon::Migrate::Command

      def initialize
        super

        @hidden = false
        @display_name = "run"
        @description = "Performs migration of data from source to destination databases"

        @cmd_map =
            [
                ["-d", "--dryrun", "Perform a test or dry run of database migration", "no_more_args", "test_migration"],
                ["-m", "--migrate", "Perform database migration", "no_more_args", "run_migration"],
                #["-u**", "--undo", "Undo migration", "no_more_args", "undo_migration"],
                #["-r**", "--redo", "Resume / redo a migration", "no_more_args", "redo_migration"],
                ["-h", "--help", "Display this help message", "no_more_args", "cmd_help"]
            ]

      end

      def test_migration
        migrate = ProjectHanlon::Migrate::Controller.new
        migrate.perform "test"
      end

      def run_migration
        migrate = ProjectHanlon::Migrate::Controller.new
        migrate.perform "run"
      end

    end
  end
end