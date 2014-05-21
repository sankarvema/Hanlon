require 'config/server'

module ProjectHanlon
  module Helper

    class Swagger

      def self.allow_swagger_access
        config = ProjectHanlon::Config::Server.instance

        config.sui_allow_access
      end

    end

  end
end