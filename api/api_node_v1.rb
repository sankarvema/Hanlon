#

require 'json'

module Razor
  module WebService
    module Node

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
        end

        resource :node do

          # GET /node
          # Query registered nodes.
          get do
            node_slice = ProjectRazor::Slice.new
            Razor::WebService::Response.new(200, 'OK', 'Success.', node_slice.get_object("nodes", :node))
          end       # end GET /node

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
              node_slice = ProjectRazor::Slice.new
              node_uuid = params[:uuid]
              node = node_slice.get_object("node_with_uuid", :node, node_uuid)
              raise ProjectRazor::Error::Slice::InvalidUUID, "Cannot Find Model with UUID: [#{node_uuid}]" unless node && (node.class != Array || node.length > 0)
              selected_option = params[:field]
              # if no params were passed in, then just return a summary for the specified node
              unless selected_option
                Razor::WebService::Response.new(200, 'OK', 'Success.', node)
              else
                if /^(attrib|attributes)$/.match(selected_option)
                  Razor::WebService::Response.new(200, 'OK', 'Success.', [Hash[node.attributes_hash.sort]])
                elsif /^(hardware|hardware_id|hardware_ids)$/.match(selected_option)
                  Razor::WebService::Response.new(200, 'OK', 'Success.', [{"hw_id" => node.hw_id}])
                else
                  raise ProjectRazor::Error::Slice::InputError, "unrecognized fieldname '#{selected_option}'"
                end
              end
            end     # end GET /node/{uuid}

          end       # end resource /node/:uuid

        end         # end resource :node

      end

    end

  end

end