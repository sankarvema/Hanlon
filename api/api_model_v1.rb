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
        SLICE_REF = ProjectRazor::Slice::Model.new([])

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
            string_ =~ /[A-Za-z0-9]{1,22}/
          end

          def get_data_ref
            Razor::WebService::Utils::get_data
          end

          def slice_success_response(slice, command, response, options = {})
            Razor::WebService::Utils::rz_slice_success_response(slice, command, response, options)
          end

          def slice_success_object(slice, command, response, options = {})
            Razor::WebService::Utils::rz_slice_success_object(slice, command, response, options)
          end

        end

        resource :model do

          # GET /model
          # Query for defined models.
          get do
            models = SLICE_REF.get_object("models", :model)
            slice_success_object(SLICE_REF, :get_all_models, models, :success_type => :generic)
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
            model = SLICE_REF.get_model_using_template_name(template)
            raise ProjectRazor::Error::Slice::InvalidModelTemplate, "Invalid Model Template [#{template}] " unless model
            image = model.image_prefix ? SLICE_REF.verify_image(model, image_uuid) : true
            raise ProjectRazor::Error::Slice::InvalidUUID, "Invalid Image UUID [#{image_uuid}] " unless image
            # use the arguments passed in (above) to create a new model
            raise ProjectRazor::Error::Slice::MissingArgument, "Must Provide Required Metadata [req_metadata_hash]" unless req_metadata_hash
            model.label = label
            model.image_uuid = image.uuid
            model.is_template = false
            req_metadata_hash.each { |key, md_hash_value|
              value = params[key]
              model.set_metadata_value(key, value, md_hash_value[:validation])
            }
            model.req_metadata_hash = req_metadata_hash
            get_data_ref.persist_object(model)
            raise(ProjectRazor::Error::Slice::CouldNotCreate, "Could not create Model") unless model
            slice_success_object(SLICE_REF, :create_model, model, :success_type => :created)
          end     # end POST /model

          resource :templates do

            # GET /model/templates
            # Query for available model templates
            get do
              # get the model templates (as an array)
              model_templates = SLICE_REF.get_child_templates(ProjectRazor::ModelTemplate)
              # then, construct the response
              slice_success_object(SLICE_REF, :get_model_templates, model_templates, :success_type => :generic)
            end     # end GET /model/templates

            resource '/:name' do

              # GET /model/templates/{name}
              # Query for a specific model template (by name)
              get do
                # get the matching model template
                model_template_name = params[:name]
                model_templates = SLICE_REF.get_child_templates(ProjectRazor::ModelTemplate)
                model_template = model_templates.select { |template| template.name == model_template_name }
                raise ProjectRazor::Error::Slice::InvalidUUID, "Cannot Find Model Template Named: [#{model_template_name}]" unless model_template && (model_template.class != Array || model_template.length > 0)
                # then, construct the response
                slice_success_object(SLICE_REF, :get_model_template_by_uuid, model_template[0], :success_type => :generic)
              end     # end GET /model/templates/{uuid}

            end     # end resource /model/templates/:uuid

          end     # end resource /model/templates

          resource '/:uuid' do

            # GET /model/{uuid}
            # Query for the state of a specific model.
            params do
              requires :uuid, type: String
            end
            get do
              model_uuid = params[:uuid]
              model = SLICE_REF.get_object("get_model_by_uuid", :model, model_uuid)
              raise ProjectRazor::Error::Slice::InvalidUUID, "Cannot Find Model with UUID: [#{model_uuid}]" unless model && (model.class != Array || model.length > 0)
              slice_success_object(SLICE_REF, :get_model_by_uuid, model, :success_type => :generic)
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
              model = SLICE_REF.get_object("model_with_uuid", :model, model_uuid)
              raise ProjectRazor::Error::Slice::InvalidUUID, "Invalid Model UUID [#{model_uuid}]" unless model && (model.class != Array || model.length > 0)
              model.web_create_metadata(req_metadata_hash) if req_metadata_hash
              model.label = label if label
              image = model.image_prefix ? SLICE_REF.verify_image(model, image_uuid) : true if image_uuid
              raise ProjectRazor::Error::Slice::InvalidUUID, "Invalid Image UUID [#{image_uuid}] " unless image || !image_uuid
              model.image_uuid = image.uuid if image
              if req_metadata_hash
                req_metadata_hash.each { |key, md_hash_value|
                  value = params[key]
                  model.set_metadata_value(key, value, md_hash_value[:validation])
                }
                model.req_metadata_hash = req_metadata_hash
              end
              raise ProjectRazor::Error::Slice::CouldNotUpdate, "Could not update Model [#{model.uuid}]" unless model.update_self
              slice_success_object(SLICE_REF, :update_model, model, :success_type => :updated)
            end     # end PUT /model/{uuid}

            # DELETE /model/{uuid}
            # Remove a Razor model (by UUID)
            params do
              requires :uuid, type: String
            end
            delete do
              model_uuid = params[:uuid]
              model = SLICE_REF.get_object("model_with_uuid", :model, model_uuid)
              raise ProjectRazor::Error::Slice::InvalidUUID, "Cannot Find Model with UUID: [#{model_uuid}]" unless model && (model.class != Array || model.length > 0)
              raise ProjectRazor::Error::Slice::CouldNotRemove, "Could not remove Model [#{model.uuid}]" unless get_data_ref.delete_object(model)
              slice_success_response(SLICE_REF, :remove_model_by_uuid, "Model [#{model.uuid}] removed", :success_type => :removed)
            end     # end DELETE /model/{uuid}

          end     # end resource /model/:uuid

        end     # end resource /model

      end

    end

  end

end
