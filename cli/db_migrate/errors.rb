

module ProjectHanlon
  module DbMigration
    ErrorCodes =
        {
            :no_error                         => 0,
            :invalid_arguments                => 1,
            :missing_config_file              => 2,
            :destination_db_not_empty         => 3,
            :unknown_error                    => 99
        }
  end
end