

module ProjectHanlon::DbMigration
  class Command

    class Run < ProjectHanlon::DbMigration::Command

      def initialize
        super

        @hidden = false
        @display_name = "run"
        @description = "Performs migration of data from source to destination databases"

      end

    end
  end
end