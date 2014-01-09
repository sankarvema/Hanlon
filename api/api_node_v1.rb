#

require 'json'
require 'api_utils'

module Razor
  module WebService
    module Node

      class APIv1 < Grape::API

        version :v1, :using => :path, :vendor => "razor"
        format :json
        default_format :json
        SLICE_REF = ProjectRazor::Slice::Node.new([])

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

          def validate_param(param)
            Razor::WebService::Utils::validate_parameter(param)
          end

          def slice_success_response(slice, command, response, options = {})
            Razor::WebService::Utils::rz_slice_success_response(slice, command, response, options)
          end

          def slice_success_object(slice, command, response, options = {})
            Razor::WebService::Utils::rz_slice_success_object(slice, command, response, options)
          end

        end

        resource :node do

          # GET /node
          # Query registered nodes.
          get do
            nodes = SLICE_REF.get_object("nodes", :node)
            slice_success_object(SLICE_REF, :get_all_nodes, nodes, :success_type => :generic)
          end       # end GET /node

          # the following description hides this endpoint from the swagger-ui-based documentation
          # (since the functionality provided by this endpoint is not intended to be used off of
          # the Razor server)
          desc 'Hide this endpoint', {
              :hidden => true
          }
          resource :checkin do

            # GET /node/checkin
            # handle a node checkin (from a Razor Microkernel instance)
            #   parameters:
            #         required:
            #           :hw_id      | String | The hardware ID of the node.          |           | Default: unavailable
            #           :last_state | String | The "state" the node is currently in. |           | Default: unavailable
            params do
              requires :hw_id, type: String
              requires :last_state, type: String
              optional :first_checkin, type: Boolean
            end
            get do
              hw_id = params[:hw_id]
              last_state = params[:last_state]
              first_checkin = params[:first_checkin]
              # Validate our args are here
              raise ProjectRazor::Error::Slice::MissingArgument, "Must Provide Hardware IDs[hw_id]" unless validate_param(hw_id)
              raise ProjectRazor::Error::Slice::MissingArgument, "Must Provide Last State[last_state]" unless validate_param(last_state)
              hw_id = hw_id.split("_") unless hw_id.is_a? Array
              raise ProjectRazor::Error::Slice::MissingArgument, "Must Provide At Least One Hardware ID [hw_id]" unless hw_id.count > 0
              # grab a couple of references we need
              engine = ProjectRazor::Engine.instance
              # if it's not the first node, check to see if the node exists
              unless first_checkin
                new_node = engine.lookup_node_by_hw_id(:hw_id => hw_id)
                if new_node
                  # if a node with this hardware id exists, simply acknowledge the checkin request
                  command = engine.mk_checkin(new_node.uuid, last_state)
                  return slice_success_response(SLICE_REF, :checkin_node, command, :mk_response => true)
                end
              end
              # otherwise, if we get this far, return a command telling the Microkernel to register
              # (either because no matching node already exists or because it's the first checkin
              # by the Microkernel)
              command = engine.mk_command(:register,{})
              slice_success_response(SLICE_REF, :checkin_node, command, :mk_response => true)
            end     # end GET /node/checkin

          end     # end resource /node/checkin

          desc 'Hide this endpoint', {
              :hidden => true
          }
          resource :register do

            # POST /node/register
            # register a node with Razor
            #   parameters:
            #     hw_id           | String | The hardware ID of the node.          |           | Default: unavailable
            #     last_state      | String | The "state" the node is currently in. |           | Default: unavailable
            #     attributes_hash | Hash   | The attributes_hash of the node.      |           | Default: unavailable
            params do
              requires "hw_id", type: String
              requires "last_state", type: String
              requires "attributes_hash", type: Hash
            end
            post do
              hw_id = params["hw_id"]
              last_state = params["last_state"]
              attributes_hash = params["attributes_hash"]
              # Validate our args are here
              raise ProjectRazor::Error::Slice::MissingArgument, "Must Provide Hardware IDs[hw_id]" unless validate_param(hw_id)
              raise ProjectRazor::Error::Slice::MissingArgument, "Must Provide Last State[last_state]" unless validate_param(last_state)
              raise ProjectRazor::Error::Slice::MissingArgument, "Must Provide Attributes Hash[attributes_hash]" unless attributes_hash.is_a? Hash and attributes_hash.size > 0
              hw_id = hw_id.split("_") if hw_id.is_a? String
              raise ProjectRazor::Error::Slice::MissingArgument, "Must Provide At Least One Hardware ID [hw_id]" unless hw_id.count > 0
              engine = ProjectRazor::Engine.instance
              new_node = engine.lookup_node_by_hw_id(:hw_id => hw_id)
              if new_node
                new_node.hw_id = new_node.hw_id | hw_id
              else
                shell_node = ProjectRazor::Node.new({})
                shell_node.hw_id = hw_id
                new_node = engine.register_new_node_with_hw_id(shell_node)
                raise ProjectRazor::Error::Slice::CouldNotRegisterNode, "Could not register new node" unless new_node
              end
              new_node.timestamp = Time.now.to_i
              new_node.attributes_hash = attributes_hash
              new_node.last_state = last_state
              raise ProjectRazor::Error::Slice::CouldNotRegisterNode, "Could not register node" unless new_node.update_self
              slice_success_response(SLICE_REF, :register_node, new_node.to_hash, :mk_response => true)
            end     # end POST /node/register

          end     # end resource /node/register

          resource '/:uuid' do
            # GET /node/{uuid}
            # Query for the state of a specific node.
            #   parameters:
            #         optional:
            #           :field      | String | The field to return. |                           | Default: unavailable
            params do
              requires :uuid, type: String
              optional :field, type: String
            end
            get do
              node_uuid = params[:uuid]
              node = SLICE_REF.get_object("node_with_uuid", :node, node_uuid)
              raise ProjectRazor::Error::Slice::InvalidUUID, "Cannot Find Model with UUID: [#{node_uuid}]" unless node && (node.class != Array || node.length > 0)
              selected_option = params[:field]
              # if no params were passed in, then just return a summary for the specified node
              unless selected_option
                slice_success_object(SLICE_REF, :get_node_by_uuid, node, :success_type => :generic)
              else
                if /^(attrib|attributes)$/.match(selected_option)
                  slice_success_response(SLICE_REF, :get_node_attributes, Hash[node.attributes_hash.sort], :success_type => :generic)
                elsif /^(hardware|hardware_id|hardware_ids)$/.match(selected_option)
                  slice_success_response(SLICE_REF, :get_node_hardware_ids, {"hw_id" => node.hw_id}, :success_type => :generic)
                else
                  raise ProjectRazor::Error::Slice::InputError, "unrecognized fieldname '#{selected_option}'"
                end
              end
            end     # end GET /node/{uuid}

          end     # end resource /node/:uuid

        end     # end resource :node

      end

    end

  end

end