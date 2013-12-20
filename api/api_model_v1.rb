#

require 'json'

module Razor
  module WebService
    module Model

      class APIv1 < Grape::API

        version :v1, :using => :path, :vendor => "razor"
        format :json
        default_format :json

        class NilResourceId < StandardError
          attr_reader :message

          def initialize(message)
            @message = message
          end
        end

        rescue_from NilResourceId do |e|
          Rack::Response.new(
              Razor::WebService::Response.new(400, e.class.name, e.message).to_json,
              400,
              { "Content-type" => "application/json" }
          )
        end

        rescue_from ProjectRazor::Error::Slice::InvalidUUID do |e|
          Rack::Response.new(
              Razor::WebService::Response.new(400, e.class.name, e.message).to_json,
              400,
              { "Content-type" => "application/json" }
          )
        end

        rescue_from Grape::Exceptions::Validation do |e|
          Rack::Response.new(
              Razor::WebService::Response.new(400, e.class.name, e.message).to_json,
              400,
              { "Content-type" => "application/json" }
          )
        end

        rescue_from :all do |e|
          raise e
          Rack::Response.new(
              Razor::WebService::Response.new(500, e.class.name, e.message).to_json,
              500,
              { "Content-type" => "application/json" }
          )
        end

        helpers do

          def content_type_header
            settings[:content_types][env['api.format']]
          end

          def api_format
            env['api.format']
          end

          def is_uuid?(string_)
            string_ =~ /[a-fA-F0-9]{8}-[a-fA-F0-9]{4}-[a-fA-F0-9]{4}-[a-fA-F0-9]{4}-[a-fA-F0-9]{12}/
          end
        end

        resource :model do

          # GET /model
          # Query registered nodes.
          get do
            model_slice = ProjectRazor::Slice.new
            Razor::WebService::Response.new(200, 'OK', 'Success.', model_slice.get_object("models", :model))
          end     # end GET /model

          resource :templates do

            # GET /model/templates
            # Query for available model templates
            get do
              model_slice = ProjectRazor::Slice.new
              model_templates = model_slice.get_child_templates(ProjectRazor::ModelTemplate)
              # convert each element of the array to a hash, then use that array of hashes
              # to construct the response
              Razor::WebService::Response.new(200, 'OK', 'Success.', model_templates.collect { |object| object.to_hash })
            end     # end GET /model/templates

          end       # end resource /model/templates

          resource '/:uuid' do

            # GET /model/{uuid}
            # Query for the state of a specific node.
            get do
              model_slice = ProjectRazor::Slice.new
              model_uuid = params[:uuid]
              model = model_slice.get_object("get_model_by_uuid", :model, model_uuid)
              raise ProjectRazor::Error::Slice::InvalidUUID, "Cannot Find Model with UUID: [#{model_uuid}]" unless model && (model.class != Array || model.length > 0)
              Razor::WebService::Response.new(200, 'OK', 'Success.', model)
            end     # end GET /model/{uuid}

          end       # end resource /model/:uuid

        end         # end resource /model

      end

    end

  end

end
