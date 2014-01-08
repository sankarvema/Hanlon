#

require 'json'
require 'api_utils'

module Razor
  module WebService
    module Policy

      class APIv1 < Grape::API

        version :v1, :using => :path, :vendor => "razor"
        format :json
        default_format :json
        SLICE_REF = ProjectRazor::Slice::Broker.new([])

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

        rescue_from ProjectRazor::Error::Slice::MethodNotAllowed do |e|
          Rack::Response.new(
              Razor::WebService::Response.new(403, e.class.name, e.message).to_json,
              403,
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

          def request_is_from_razor_subnet(ip_addr)
            Razor::WebService::Utils::request_from_razor_subnet?(ip_addr)
          end

          def get_data_ref
            Razor::WebService::Utils::get_data
          end

          def slice_success_response(slice, command, response, options = {})
            Razor::WebService::Utils::rz_slice_success_response(slice, command, response, options)
          end

          def slice_success_object_array(slice, command, response, options = {})
            Razor::WebService::Utils::rz_slice_success_object_array(slice, command, response, options)
          end

          def make_callback(active_model, callback_namespace, command_array)
            callback = active_model.model.callback[callback_namespace]
            raise ProjectRazor::Error::Slice::NoCallbackFound, "Missing callback" unless callback
            node = get_data_ref.fetch_object_by_uuid(:node, active_model.node_uuid)
            callback_return = active_model.model.callback_init(callback, command_array, node, active_model.uuid, active_model.broker)
            active_model.update_self
            puts callback_return
          end

        end

        resource :policy do

          # GET /policy
          # Query for defined policies.
          get do
            policies = SLICE_REF.get_object("policies", :policy)
            slice_success_object_array(SLICE_REF, :get_all_policies, policies, :success_type => :generic)
          end     # end GET /policy

          # POST /policy
          # Create a Razor policy
          #   parameters:
          #     template          | String | The "template" to use for the new policy |         | Default: unavailable
          #     label             | String | The "label" to use for the new policy    |         | Default: unavailable
          #     model_uuid        | String | The UUID of the model to use             |         | Default: unavailable
          #     tags              | String | The (comma-separated) list of tags       |         | Default: unavailable
          #     broker_uuid       | String | The UUID of the broker to use            |         | Default: "none"
          #     enabled           | String | A flag indicating if policy is enabled   |         | Default: "false"
          #     maximum           | String | The maximum_count for the policy         |         | Default: "0"
          params do
            requires "template", type: String
            requires "label", type: String
            requires "model_uuid", type: String
            requires "tags", type: String
            optional "broker_uuid", type: String, default:  "none"
            optional "enabled", type: String, default: "false"
            optional "maximum", type: String, default: "0"
          end
          post do
            # grab values for required parameters
            policy_template = params["template"]
            label = params["label"]
            model_uuid = params["model_uuid"]
            broker_uuid = params["broker_uuid"]
            tags = params["tags"]
            enabled = params["enabled"]
            maximum = params["maximum"]
            # check for errors in inputs
            policy = SLICE_REF.new_object_from_template_name(POLICY_PREFIX, policy_template)
            raise ProjectRazor::Error::Slice::InvalidPolicyTemplate, "Policy Template is not valid [#{policy_template}]" unless policy
            model = SLICE_REF.get_object("model_by_uuid", :model, model_uuid)
            raise ProjectRazor::Error::Slice::InvalidUUID, "Invalid Model UUID [#{model_uuid}]" unless model && (model.class != Array || model.length > 0)
            raise ProjectRazor::Error::Slice::InvalidModel, "Invalid Model Type [#{model.template}] != [#{policy.template}]" unless policy.template.to_s == model.template.to_s
            broker = SLICE_REF.get_object("broker_by_uuid", :broker, broker_uuid)
            raise ProjectRazor::Error::Slice::InvalidUUID, "Invalid Broker UUID [#{broker_uuid}]" unless (broker && (broker.class != Array || broker.length > 0)) || broker_uuid == "none"
            tags = tags.split(",") unless tags.class.to_s == "Array"
            raise ProjectRazor::Error::Slice::MissingTags, "Must provide at least one tag ['tag(,tag)']" unless tags.count > 0
            raise ProjectRazor::Error::Slice::InvalidMaximumCount, "Policy maximum count must be a valid integer" unless maximum.to_i.to_s == maximum
            raise ProjectRazor::Error::Slice::InvalidMaximumCount, "Policy maximum count must be > 0" unless maximum.to_i >= 0
            # Flesh out the policy
            policy.label         = label
            policy.model         = model
            policy.broker        = broker
            policy.tags          = tags
            policy.enabled       = enabled
            policy.is_template   = false
            policy.maximum_count = maximum
            # Add policy
            policy_rules         = ProjectRazor::Policies.instance
            raise(ProjectRazor::Error::Slice::CouldNotCreate, "Could not create Policy") unless policy_rules.add(policy)
            slice_success_object_array(SLICE_REF, :create_policy, [policy], :success_type => :created)
          end     # end POST /policy

          resource :templates do

            # GET /policy/templates
            # Query for available policy templates
            get do
              policy_templates = SLICE_REF.get_child_templates(ProjectRazor::PolicyTemplate)
              # then, construct the response
              slice_success_object_array(SLICE_REF, :get_policy_templates, policy_templates, :success_type => :generic)
            end     # end GET /policy/templates

          end     # end resource /policy/templates

          # the following description hides this endpoint from the swagger-ui-based documentation
          # (since the functionality provided by this endpoint is not intended to be used off of
          # the Razor server)
          desc 'Hide this endpoint', {
              :hidden => true
          }
          resource :callback do

            resource '/:uuid' do

              resource '/:namespace_and_args', requirements: { namespace_and_args: /.*/ } do

                # GET /policy/callback/{uuid}/{namespace_and_args}
                # Make a callback "call" (used during the install/broker-handoff process to track progress)
                before do
                  # only allow access to this resource from the Razor subnet
                  unless request_is_from_razor_subnet(env['REMOTE_ADDR'])
                    env['api.format'] = :text
                    raise ProjectRazor::Error::Slice::MethodNotAllowed, "Remote Access Forbidden; access to /policy/callback resource is not allowed from outside of the Razor subnet"
                  end
                end
                params do
                  requires :uuid, type: String
                  requires :namespace_and_args, type: String
                end
                get do
                  # get (and check) the required parameters
                  active_model_uuid  = params[:uuid]
                  raise ProjectRazor::Error::Slice::MissingActiveModelUUID, "Missing active model uuid" unless SLICE_REF.validate_arg(active_model_uuid)
                  command_args = params[:namespace_and_args].split('/')
                  callback_namespace = namespace_and_args.shift
                  raise ProjectRazor::Error::Slice::MissingCallbackNamespace, "Missing callback namespace" unless SLICE_REF.validate_arg(callback_namespace)
                  engine       = ProjectRazor::Engine.instance
                  active_model = nil
                  engine.get_active_models.each { |am| active_model = am if am.uuid == active_model_uuid }
                  raise ProjectRazor::Error::Slice::ActiveModelInvalid, "Active Model Invalid" unless active_model
                  logger.debug "Active bound policy found for callback: #{callback_namespace}"
                  make_callback(active_model, callback_namespace, command_array)
                end     # end GET /policy/callback/{uuid}/{namespace_and_args}

              end     # end resource /policy/callback/:uuid/:namespace_and_args

            end     # end resource /policy/callback/:uuid

          end     # end resource /policy/callback

          resource '/:uuid' do

            # GET /policy/{uuid}
            # Query for the state of a specific policy.
            params do
              requires :uuid, type: String
            end
            get do
              policy_uuid = params[:uuid]
              policy = SLICE_REF.get_object("get_policy_by_uuid", :policy, policy_uuid)
              raise ProjectRazor::Error::Slice::InvalidUUID, "Cannot Find Policy with UUID: [#{policy_uuid}]" unless policy && (policy.class != Array || policy.length > 0)
              slice_success_object_array(SLICE_REF, :get_policy_by_uuid, [policy], :success_type => :generic)
            end     # end GET /policy/{uuid}

            # PUT /policy/{uuid}
            # Update a Razor policy (any of the the label, image UUID, or req_metadata_hash
            # can be updated using this endpoint; note that the policy template cannot be updated
            # once a policy is created
            #   parameters:
            #     label             | String | The new "label" value                    |         | Default: unavailable
            #     model_uuid        | String | The new model UUID value                 |         | Default: unavailable
            #     tags              | String | The new (comma-separated) list of tags   |         | Default: unavailable
            #     broker_uuid       | String | The new broker UUID value                |         | Default: unavailable
            #     new_line_number   | String | The new line number in the policy table  |         | Default: unavailable
            #     enabled           | String | A new "enabled flag" value               |         | Default: unavailable
            #     maximum           | String | The new maximum_count value              |         | Default: unavailable
            params do
              requires :uuid, type: String
              optional "label", type: String, default: nil
              optional "model_uuid", type: String, default: nil
              optional "tags", type: String, default: nil
              optional "broker_uuid", type: String, default: nil
              optional "new_line_number", type: String, default: nil
              optional "enabled", type: String, default: nil
              optional "maximum", type: String, default: nil
            end
            put do
              # get optional parameters
              label = params["label"]
              model_uuid = params["model_uuid"]
              tags = params["tags"]
              broker_uuid = params["broker_uuid"]
              new_line_number = params["new_line_number"]
              enabled = params["enabled"]
              maximum = params["maximum"]

              # and check the values that were passed in (skipping those that were not)
              policy_uuid = params[:uuid]
              policy = SLICE_REF.get_object("policy_with_uuid", :policy, policy_uuid)
              raise ProjectRazor::Error::Slice::InvalidUUID, "Invalid Policy UUID [#{policy_uuid}]" unless policy && (policy.class != Array || policy.length > 0)

              if tags
                tags = tags.split(",") if tags.is_a? String
                raise ProjectRazor::Error::Slice::MissingArgument, "Policy Tags ['tag(,tag)']" unless tags.count > 0
              end
              model = nil
              if model_uuid
                model = SLICE_REF.get_object("model_by_uuid", :model, model_uuid)
                raise ProjectRazor::Error::Slice::InvalidUUID, "Invalid Model UUID [#{model_uuid}]" unless model && (model.class != Array || model.length > 0)
                raise ProjectRazor::Error::Slice::InvalidModel, "Invalid Model Type [#{model.label}]" unless policy.template == model.template
              end
              broker = nil
              if broker_uuid
                broker = SLICE_REF.get_object("broker_by_uuid", :broker, broker_uuid)
                raise ProjectRazor::Error::Slice::InvalidUUID, "Invalid Broker UUID [#{broker_uuid}]" unless (broker && (broker.class != Array || broker.length > 0)) || broker_uuid == "none"
              end
              new_line_number = (new_line_number ? new_line_number.strip : nil)
              raise ProjectRazor::Error::Slice::InputError, "New index '#{new_line_number}' is not an integer" if new_line_number && !/^[+-]?\d+$/.match(new_line_number)
              if enabled
                raise ProjectRazor::Error::Slice::InputError, "Enabled flag must have a value of 'true' or 'false'" if enabled != "true" && enabled != "false"
              end
              if maximum
                raise ProjectRazor::Error::Slice::InvalidMaximumCount, "Policy maximum count must be a valid integer" unless maximum.to_i.to_s == maximum
                raise ProjectRazor::Error::Slice::InvalidMaximumCount, "Policy maximum count must be > 0" unless maximum.to_i >= 0
              end
              # Update object properties
              policy.label = label if label
              policy.model = model if model
              policy.broker = broker if broker
              policy.tags = tags if tags
              policy.enabled = enabled if enabled
              policy.maximum_count = maximum if maximum
              if new_line_number
                policy_rules = ProjectRazor::Policies.instance
                policy_rules.move_policy_to_idx(policy.uuid, new_line_number.to_i)
              end
              # Update object
              raise ProjectRazor::Error::Slice::CouldNotUpdate, "Could not update Broker Target [#{broker.uuid}]" unless policy.update_self
              slice_success_object_array(SLICE_REF, :update_policy, [policy], :success_type => :updated)
            end     # end PUT /policy/{uuid}

            # DELETE /policy/{uuid}
            # Remove a Razor policy (by UUID)
            params do
              requires :uuid, type: String
            end
            delete do
              policy_uuid = params[:uuid]
              policy = SLICE_REF.get_object("policy_with_uuid", :policy, policy_uuid)
              raise ProjectRazor::Error::Slice::InvalidUUID, "Cannot Find Policy with UUID: [#{policy_uuid}]" unless policy && (policy.class != Array || policy.length > 0)
              raise ProjectRazor::Error::Slice::CouldNotRemove, "Could not remove Policy [#{policy.uuid}]" unless get_data_ref.delete_object(policy)
              slice_success_response(SLICE_REF, :remove_policy_by_uuid, "Policy [#{policy.uuid}] removed", :success_type => :removed)
            end     # end DELETE /policy/{uuid}

          end     # end resource /policy/:uuid

        end     # end resource /policy

      end

    end

  end

end
