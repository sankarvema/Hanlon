#

require 'json'
require 'api_utils'

module Hanlon
  module WebService
    module Node

      class APIv1 < Grape::API

        version :v1, :using => :path, :vendor => "hanlon"
        format :json
        default_format :json
        SLICE_REF = ProjectHanlon::Slice::Node.new([])

        rescue_from ProjectHanlon::Error::Slice::InvalidUUID,
                    ProjectHanlon::Error::Slice::InvalidCommand,
                    ProjectHanlon::Error::Slice::MissingArgument,
                    ProjectHanlon::Error::Slice::InputError,
                    Grape::Exceptions::Validation do |e|
          Rack::Response.new(
              Hanlon::WebService::Response.new(400, e.class.name, e.message).to_json,
              400,
              { "Content-type" => "application/json" }
          )
        end

        rescue_from ProjectHanlon::Error::Slice::CouldNotRegisterNode do |e|
          Rack::Response.new(
              Hanlon::WebService::Response.new(404, e.class.name, e.message).to_json,
              404,
              { "Content-type" => "application/json" }
          )
        end

        rescue_from :all do |e|
          #raise e
          Rack::Response.new(
              Hanlon::WebService::Response.new(500, e.class.name, e.message).to_json,
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
            string_ =~ /^[A-Za-z0-9]{1,22}$/
          end

          def validate_param(param)
            Hanlon::WebService::Utils::validate_parameter(param)
          end

          def slice_success_response(slice, command, response, options = {})
            Hanlon::WebService::Utils::rz_slice_success_response(slice, command, response, options)
          end

          def slice_success_object(slice, command, response, options = {})
            Hanlon::WebService::Utils::rz_slice_success_object(slice, command, response, options)
          end

        end

        resource :node do

          # GET /node
          # Query registered nodes.
          desc "Retrieve a list of all node instances"
          params do
            optional :uuid, type: String, desc: "The Hardware ID (SMBIOS UUID) of the node."
          end
          get do
            uuid = params[:uuid]
            if uuid
              node = ProjectHanlon::Engine.instance.lookup_node_by_hw_id({:uuid => uuid, :mac_id => []})
              raise ProjectHanlon::Error::Slice::InvalidUUID, "Cannot Find Node with Hardware ID: [#{uuid}]" unless node
              nodes = [node]
            else
              nodes = SLICE_REF.get_object("nodes", :node)
            end
            slice_success_object(SLICE_REF, :get_all_nodes, nodes, :success_type => :generic)
          end       # end GET /node

          # the following description hides this endpoint from the swagger-ui-based documentation
          # (since the functionality provided by this endpoint is not intended to be used off of
          # the Hanlon server)
          desc 'Hide this endpoint', {
              :hidden => true
          }
          resource :checkin do

            # GET /node/checkin
            # handle a node checkin (from a Hanlon Microkernel instance)
            #   parameters:
            #         required:
            #           :last_state     | String | The "state" the node is currently in.    |           | Default: unavailable
            #         optional (although one of these two must be specified):
            #           :uuid           | String | The UUID for the node (from the BIOS).   |           | Default: unavailable
            #           :mac_id         | String | The MAC addresses for the node's NICs.   |           | Default: unavailable
            #         optional
            #           :first_checkin  | Boolean | Indicates if is first checkin (or not). |           | Default: unavailable
            #         allowed for backwards compatibility (although will throw an error if used with 'mac_id')
            #           :hw_id          | String | The MAC addresses for the node's NICs.   |      | Default: unavailable

            params do
              requires :last_state, type: String, desc: "The last state received by the Microkernel"
              optional :uuid, type: String, desc: "The UUID for the node"
              optional :mac_id, type: String, desc: "The MAC addresses of the node's NICs."
              optional :hw_id, type: String, desc: "The MAC addresses of the node's NICs."
              optional :first_checkin, type: Boolean, desc: "Used to indicate if is first checkin (or not) by MK"
            end
            desc "Handle a node checkin (by a Microkernel instance)"
            get do
              uuid = params["uuid"].upcase if params["uuid"]
              mac_id = params[:mac_id].upcase.split("_") if params[:mac_id]
              # the following parameter is only used for backwards compatibility (with
              # previous versions of Hanlon, which used a 'hw_id' field during the boot
              # process instead of the new 'mac_id' field)
              hw_id = params[:hw_id].upcase.split("_") if params[:hw_id]
              raise ProjectHanlon::Error::Slice::InvalidCommand, "The hw_id parameter is only allowed for backwards compatibility; use with the mac_id parameter is not allowed" if (hw_id && mac_id)
              mac_id = hw_id if hw_id
              # check to make sure that either the mac_id or the uuid were passed in (or that the
              # hw_id was included instead of the mac_id if it's an old Microkernel checking in, in
              # which case the mac_id will be defined here)
              raise ProjectHanlon::Error::Slice::MissingArgument, "At least one of the optional arguments (uuid or mac_id) must be specified" unless ((uuid && uuid.length > 0) || (mac_id && !(mac_id.empty?)))
              last_state = params[:last_state]
              first_checkin = params[:first_checkin]
              # Validate our args are here
              # raise ProjectHanlon::Error::Slice::MissingArgument, "Must Provide Hardware IDs[hw_id]" unless validate_param(hw_id)
              raise ProjectHanlon::Error::Slice::MissingArgument, "Must Provide Last State[last_state]" unless validate_param(last_state)
              mac_id = mac_id.split("_") if mac_id && mac_id.is_a?(String)
              # raise ProjectHanlon::Error::Slice::MissingArgument, "Must Provide At Least One Hardware ID [hw_id]" unless hw_id.count > 0
              # grab a couple of references we need
              engine = ProjectHanlon::Engine.instance
              # if it's not the first node, check to see if the node exists
              unless first_checkin
                new_node = engine.lookup_node_by_hw_id({:uuid => uuid, :mac_id => mac_id})
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
            # register a node with Hanlon
            #   parameters:
            #     required:
            #       last_state      | String | The "state" the node is currently in.  |           | Default: unavailable
            #       attributes_hash | Hash   | The attributes_hash of the node.       |           | Default: unavailable
            #     optional (although one of these two must be specified):
            #       uuid            | String | The UUID for the node (from the BIOS). |           | Default: unavailable
            #       mac_id          | String | The MAC addresses for the node's NICs. |           | Default: unavailable
            #         allowed for backwards compatibility (although will throw an error if used with 'mac_id')
            #           :hw_id      | String | The MAC addresses for the node's NICs. |           | Default: unavailable
            desc "Handle a node registration request (by a Microkernel instance)"
            params do
              requires "last_state", type: String, desc: "The last state received by the Microkernel"
              requires "attributes_hash", type: Hash, desc: "A hash of the node's attributes (from facter, lshw, etc.)"
              optional "uuid", type: String, desc: "The UUID for the node"
              optional "mac_id", type: String, desc: "The MAC addresses of the node's NICs."
            end
            post do
              uuid = params["uuid"].upcase if params["uuid"]
              mac_id = params["mac_id"].upcase.split("_") if params[:mac_id]
              # the following parameter is only used for backwards compatibility (with
              # previous versions of Hanlon, which used a 'hw_id' field during the boot
              # process instead of the new 'mac_id' field)
              hw_id = params["hw_id"].upcase.split("_") if params[:hw_id]
              raise ProjectHanlon::Error::Slice::InvalidCommand, "The hw_id parameter is only allowed for backwards compatibility; use with the mac_id parameter is not allowed" if (hw_id && mac_id)
              mac_id = hw_id if hw_id
              # check to make sure that either the mac_id or the uuid were passed in (or that the
              # hw_id was included instead of the mac_id if it's an old Microkernel registering, in
              # which case the mac_id will be defined here)
              raise ProjectHanlon::Error::Slice::MissingArgument, "At least one of the optional arguments (uuid or mac_id) must be specified" unless ((uuid && uuid.length > 0) || (mac_id && !(mac_id.empty?)))
              last_state = params["last_state"]
              attributes_hash = params["attributes_hash"]
              # Validate our args are here
              raise ProjectHanlon::Error::Slice::MissingArgument, "Must Provide Last State[last_state]" unless validate_param(last_state)
              raise ProjectHanlon::Error::Slice::MissingArgument, "Must Provide Attributes Hash[attributes_hash]" unless attributes_hash.is_a? Hash and attributes_hash.size > 0
              # mac_id = mac_id.split("_") if mac_id && mac_id.is_a?(String)
              engine = ProjectHanlon::Engine.instance
              new_node = engine.lookup_node_by_hw_id({:uuid => uuid, :mac_id => mac_id})
              if new_node
                if uuid && !(uuid.empty?)
                  new_node.hw_id = [uuid]
                else
                  new_node.hw_id = new_node.hw_id | mac_id
                end
              else
                shell_node = ProjectHanlon::Node.new({})
                if uuid && !(uuid.empty?)
                  shell_node.hw_id = [uuid]
                else
                  shell_node.hw_id = mac_id
                end
                new_node = engine.register_new_node_with_hw_id(shell_node)
                raise ProjectHanlon::Error::Slice::CouldNotRegisterNode, "Could not register new node" unless new_node
              end
              new_node.timestamp = Time.now.to_i
              new_node.attributes_hash = attributes_hash
              new_node.last_state = last_state
              raise ProjectHanlon::Error::Slice::CouldNotRegisterNode, "Could not register node" unless new_node.update_self
              slice_success_response(SLICE_REF, :register_node, new_node.to_hash, :mk_response => true)
            end     # end POST /node/register

          end     # end resource /node/register

          resource '/:uuid' do
            # GET /node/{uuid}
            # Query for the state of a specific node.
            #   parameters:
            #         optional:
            #           :field      | String | The field to return. |                           | Default: unavailable
            desc "Get the details for a specific node (by UUID)"
            params do
              requires :uuid, type: String, desc: "The node's UUID"
              optional :field, type: String, desc: "Name of field to return ('attributes' or 'hardware_id')"
            end
            get do
              node_uuid = params[:uuid]
              node = SLICE_REF.get_object("node_with_uuid", :node, node_uuid)
              raise ProjectHanlon::Error::Slice::InvalidUUID, "Cannot Find Node with UUID: [#{node_uuid}]" unless node && (node.class != Array || node.length > 0)
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
                  raise ProjectHanlon::Error::Slice::InputError, "unrecognized fieldname '#{selected_option}'"
                end
              end
            end     # end GET /node/{uuid}

          end     # end resource /node/:uuid

        end     # end resource :node

      end

    end

  end

end
