#

require 'json'
require 'api_utils'

module Hanlon
  module WebService
    module Boot

      class APIv1 < Grape::API

        version :v1, :using => :path, :vendor => "hanlon"
        format :json
        default_format :json

        rescue_from ProjectHanlon::Error::Slice::MethodNotAllowed do |e|
          Rack::Response.new(
              Hanlon::WebService::Response.new(403, e.class.name, e.message).to_json,
              403,
              { "Content-type" => "application/json" }
          )
        end

        rescue_from Grape::Exceptions::Validation do |e|
          Rack::Response.new(
              Hanlon::WebService::Response.new(400, e.class.name, e.message).to_json,
              400,
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

          def request_is_from_hanlon_subnet(ip_addr)
            Hanlon::WebService::Utils::request_from_hanlon_subnet?(ip_addr)
          end

        end

        # the following code snippet hides this endpoint from the swagger-ui-based documentation
        # (since the functionality provided by this endpoint is not intended to for users, instead
        # this functionality is used during the iPXE boot process to retrieve the appropriate
        # iPXE-boot script for a given node based on it's hardware ID nad the MAC address of the
        # interface that it received it's DHCP assignment from)
        desc 'Hide this endpoint', {
            :hidden => true
        }
        resource :boot do

          # GET /boot
          # Query for the boot script for a node
          #   parameters:
          #         required:
          #           :hw_id      | String | The hardware ID for the node. |                   | Default: unavailable
          #           :dhcp_mac   | String | The MAC address the DHCP NIC. |                   | Default: unavailable
          desc "Retrieve the iPXE-boot script (for a node)"
          before do
            # only allow access to this resource from the Hanlon subnet
            unless request_is_from_hanlon_subnet(env['REMOTE_ADDR'])
              env['api.format'] = :text
              raise ProjectHanlon::Error::Slice::MethodNotAllowed, "Remote Access Forbidden; access to /boot resource is not allowed from outside of the Hanlon subnet"
            end
          end
          params do
            requires :hw_id, type: String, desc: "The hardware ID for the node"
            requires :dhcp_mac, type: String, desc: "The MAC address of the DHCP NIC"
          end
          get do
            hw_id = params[:hw_id].split("_")
            dhcp_mac = params[:dhcp_mac]
            hw_id.collect! {|x| x.upcase.gsub(':', '') }
            env['api.format'] = :text
            ProjectHanlon::Engine.instance.boot_checkin(:hw_id => hw_id, :dhcp_mac => dhcp_mac)
          end     # end GET /boot

        end     # end resource /boot

      end

    end

  end

end
