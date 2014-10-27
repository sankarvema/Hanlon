require 'db_migrate/errors'
require 'db_migrate/command_factory'
require 'db_migrate/command'

require 'helpers/console'

module ProjectHanlon::DbMigrate
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