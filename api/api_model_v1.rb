#

require 'json'
require 'api_utils'

module Razor
  module WebService
    module Model

      class APIv1 < Grape::API

        version :v1, :using => :path, :vendor => "razor"
        format :json
        default_format :json

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

          def get_data_ref
            Razor::WebService::Utils::get_data
          end

        end

        resource :model do

          # GET /model
          # Query registered nodes.
          get do
            slice_ref = ProjectRazor::Slice.new
            Razor::WebService::Response.new(200, 'OK', 'Success.', slice_ref.get_object("models", :model))
          end     # end GET /model

          # POST /model
          # Create a Razor model
          #   parameters:
          #     template          | String | The "template" to use for the new model |         | Default: unavailable
          #     label             | String | The "label" to use for the new model    |         | Default: unavailable
          #     image_uuid        | String | The UUID of the image to use            |         | Default: unavailable
          #     req_metadata_hash | Hash   | The metadata to use for the new model   |         | Default: unavailable
          params do
            requires "template", type: String
            requires "label", type: String
            requires "image_uuid", type: String
            requires "req_metadata_hash", type: Hash
          end
          post do
            template = params["template"]
            label = params["label"]
            image_uuid = params["image_uuid"]
            req_metadata_hash = params["req_metadata_hash"]
            # check the values that were passed in
            slice_ref = ProjectRazor::Slice::Model.new([])
            model = slice_ref.verify_template(template)
            raise ProjectRazor::Error::Slice::InvalidModelTemplate, "Invalid Model Template [#{template}] " unless model
            image = model.image_prefix ? slice_ref.verify_image(model, image_uuid) : true
            raise ProjectRazor::Error::Slice::InvalidUUID, "Invalid Image UUID [#{image_uuid}] " unless image
            # use the arguments passed in (above) to create a new model
            raise ProjectRazor::Error::Slice::MissingArgument, "Must Provide Required Metadata [req_metadata_hash]" unless
                req_metadata_hash
            model.web_create_metadata(req_metadata_hash)
            model.label = label
            model.image_uuid = image.uuid
            model.is_template = false
            get_data_ref.persist_object(model)
            raise(ProjectRazor::Error::Slice::CouldNotCreate, "Could not create Model") unless model
            Razor::WebService::Response.new(200, 'OK', 'Model created', model)
          end     # end PUT /model/{uuid}

          resource :templates do

            # GET /model/templates
            # Query for available model templates
            get do
              slice_ref = ProjectRazor::Slice.new
              model_templates = slice_ref.get_child_templates(ProjectRazor::ModelTemplate)
              # convert each element of the array to a hash, then use that array of hashes
              # to construct the response
              Razor::WebService::Response.new(200, 'OK', 'Success.', model_templates.collect { |object| object.to_hash })
            end     # end GET /model/templates

          end       # end resource /model/templates

          resource '/:uuid' do

            # GET /model/{uuid}
            # Query for the state of a specific node.
            params do
              requires :uuid, type: String
            end
            get do
              slice_ref = ProjectRazor::Slice.new
              model_uuid = params[:uuid]
              model = slice_ref.get_object("get_model_by_uuid", :model, model_uuid)
              raise ProjectRazor::Error::Slice::InvalidUUID, "Cannot Find Model with UUID: [#{model_uuid}]" unless model && (model.class != Array || model.length > 0)
              Razor::WebService::Response.new(200, 'OK', 'Success.', model)
            end     # end GET /model/{uuid}

            # PUT /model/{uuid}
            # Update a Razor model
            #   parameters:
            #     required:
            #       :json_hash | Hash |
            params do
              requires :json_hash, type: String
            end
            put do

            end     # end PUT /model/{uuid}

          end       # end resource /model/:uuid

        end         # end resource /model

      end

    end

  end

end
