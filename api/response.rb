#

module Razor
  module WebService
    # Response class
    class Response
      attr_reader :code, :type, :description, :entity, :request_id, :entity_count

      def initialize(code, type, description, entity = nil, request_id = nil)
        # HTTP Code
        @code        = code
        # Type of code: accepted, created, etc
        @type        = type
        # Human readable description of response
        @description = description
        # Optional Entity
        @entity      = entity
        # Optional tracking of requests using message tracker
        @request_id  = request_id
        # Entity count if is an Array
        if entity && entity.respond_to?(:each)
          @entity_count = entity.count
        else
          @entity_count = nil
        end
      end

      def to_hash
        # build a Hash representing our response
        hash = { :response =>
                     {
                         :result => {
                             :code        => code,
                             :type        => type,
                             :description => description,
                         }
                     }
        }

        if entity_count
          hash[:response][:result][:entity_count] = entity_count
        end
        if entity
          if entity.respond_to? :each
            entities = []
            entity.each_with_index do |e|
              entities << { :entity => e.to_hash }
            end
            hash[:response][:entities] = entities
          else
            hash[:response][:entity] = entity.to_hash
          end
        end
        if request_id
          hash[:response][:request_status] = {
              :id            => request_id,
              :location_path => request_location_path
          }
        end
        hash
      end

      def to_json
        JSON.pretty_generate(to_hash)
      end

      def request_location_path
        "#{Zombie::Rez::WebService::Resource::App.base_uri}/v1/request/#{request_id}"
      end

    end
  end
end