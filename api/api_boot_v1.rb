#

require 'json'

module Razor
  module WebService
    module Boot

      class APIv1 < Grape::API

        version :v1, :using => :path, :vendor => "razor"
        format :json
        default_format :json

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

        end

        resource :boot do

          # GET /boot
          # Query for the boot script for a node
          #   parameters:
          #         required:
          #           :hw_id      | String | The hardware ID for the node. |                   | Default: unavailable
          #           :dhcp_mac   | String | The MAC address the DHCP NIC. |                   | Default: unavailable
          params do
            requires :hw_id, type: String
            requires :dhcp_mac, type: String
          end
          get do
            hw_id = params[:hw_id].split("_")
            dhcp_mac = params[:dhcp_mac]
            hw_id.collect! {|x| x.upcase.gsub(':', '') }
            env['api.format'] = :text
            ProjectRazor::Engine.instance.boot_checkin(:hw_id => hw_id, :dhcp_mac => dhcp_mac)
          end     # end GET /boot

        end         # end resource /boot

      end

    end

  end

end
