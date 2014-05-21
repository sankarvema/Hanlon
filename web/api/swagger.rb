#

require 'json'
require 'helper/swagger'

module Hanlon
  module WebService

    class Swagger < Grape::API

      format :json
      default_format :json

      #if SERVICE_CONFIG[:config][:swagger_ui] && SERVICE_CONFIG[:config][:swagger_ui][:allow_access]
      if ProjectHanlon::Helper::Swagger.allow_swagger_access
        resource :swagger_config do
          get do
            #SERVICE_CONFIG[:config][:swagger_ui].to_json
            "{ \"message\" : \"Deprecated\" }"
          end
        end
      end

    end
  end
end