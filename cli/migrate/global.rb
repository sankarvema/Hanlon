require 'migrate/errors'
require 'migrate/command'
require 'migrate/factory'

require 'helpers/console'

module ProjectHanlon::Migrate
end


module ProjectHanlon::Migrate
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