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

          def slice_success_web(slice, command, response, options = {})
            Razor::WebService::Utils::rz_slice_success_web(slice, command, response, options)
          end

          def response_with_status_web(slice, command, response, options = {})
            Razor::WebService::Utils::rz_response_with_status(slice, command, response, options)
          end

        end

        resource :model do

          # GET /model
          # Query for defined models.
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
            model_slice = ProjectRazor::Slice::Model.new([])
            model = model_slice.verify_template(template)
            raise ProjectRazor::Error::Slice::InvalidModelTemplate, "Invalid Model Template [#{template}] " unless model
            image = model.image_prefix ? model_slice.verify_image(model, image_uuid) : true
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
            response_with_status_web(model_slice, :create_model, [model], :success_type => :created)
          end     # end POST /model

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

          end     # end resource /model/templates

          resource '/:uuid' do

            # GET /model/{uuid}
            # Query for the state of a specific model.
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
            # Update a Razor model (any of the the label, image UUID, or req_metadata_hash
            # can be updated using this endpoint; note that the model template cannot be updated
            # once a model is created
            #   parameters:
            #     label             | String | The "label" to use for the new model    |         | Default: unavailable
            #     image_uuid        | String | The UUID of the image to use            |         | Default: unavailable
            #     req_metadata_hash | Hash   | The metadata to use for the new model   |         | Default: unavailable
            params do
              requires :uuid, type: String
              optional "label", type: String
              optional "image_uuid", type: String
              optional "req_metadata_hash", type: Hash
            end
            put do
              # get the input parameters that were passed in as part of the request
              # (at least one of these should be a non-nil value)
              label = params["label"]
              image_uuid = params["image_uuid"]
              req_metadata_hash = params["req_metadata_hash"]
              # get the UUID for the model being updated
              model_uuid = params[:uuid]
              # check the values that were passed in (and gather new meta-data if
              # the --change-metadata flag was included in the update command and the
              # command was invoked via the CLI...it's an error to use this flag via
              # the RESTful API, the req_metadata_hash should be used instead)
              model_slice = ProjectRazor::Slice::Model.new([])
              model = model_slice.get_object("model_with_uuid", :model, model_uuid)
              raise ProjectRazor::Error::Slice::InvalidUUID, "Invalid Model UUID [#{model_uuid}]" unless model && (model.class != Array || model.length > 0)
              model.web_create_metadata(req_metadata_hash) if req_metadata_hash
              model.label = label if label
              image = model.image_prefix ? model_slice.verify_image(model, image_uuid) : true if image_uuid
              raise ProjectRazor::Error::Slice::InvalidUUID, "Invalid Image UUID [#{image_uuid}] " unless image || !image_uuid
              model.image_uuid = image.uuid if image
              raise ProjectRazor::Error::Slice::CouldNotUpdate, "Could not update Model [#{model.uuid}]" unless model.update_self
              response_with_status_web(model_slice, :update_model, [model], :success_type => :updated)
            end     # end PUT /model/{uuid}

            # DELETE /model/{uuid}
            # Remove a Razor model (by UUID)
            params do
              requires :uuid, type: String
            end
            delete do
              model_slice = ProjectRazor::Slice::Model.new([])
              model_uuid = params[:uuid]
              model = model_slice.get_object("model_with_uuid", :model, model_uuid)
              raise ProjectRazor::Error::Slice::InvalidUUID, "Cannot Find Model with UUID: [#{model_uuid}]" unless model && (model.class != Array || model.length > 0)
              raise ProjectRazor::Error::Slice::CouldNotRemove, "Could not remove Model [#{model.uuid}]" unless get_data_ref.delete_object(model)
              slice_success_web(model_slice, :remove_model_by_uuid, "Model [#{model.uuid}] removed", :success_type => :removed)
            end     # end DELETE /model/{uuid}

          end     # end resource /model/:uuid

        end     # end resource /model

      end

    end

  end

end
