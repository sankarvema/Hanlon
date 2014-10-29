require 'db_migrate/errors'
require 'db_migrate/command_factory'
require 'db_migrate/command'
require 'db_migrate/migration_rule'
require 'db_migrate/migration_controller'


require 'helpers/console'

module ProjectHanlon::DbMigration
end

module ProjectHanlon::DbMigration
  class Global
    @@args=nil

    def self.args
      @@args
    end

    def self.args=(val)
      @@args=val
    end
  end
end