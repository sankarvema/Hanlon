#

require 'json'
require 'facter'
require 'facter/util/ip'
require 'ipaddr'

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
          after_validation do
            # only allow for access to this resource from the localhost or the
            # subnet being managed by the Razor server; to test this, first we
            # need to retrieve a few parameters (the Razor server's IP address,
            # the array of interfaces on the local machine, and the IP address
            # of the client making the request)
            razor_server_ip = ProjectRazor.config.to_hash["@mk_uri"].match(/\/\/([0-9]+\.[0-9]+\.[0-9]+\.[0-9]+)/)[1]
            interface_array = Facter::Util::IP.get_interfaces
            remote_addr = env['REMOTE_ADDR']
            # then, need to test each interface to see if that interface includes
            # the remote_addr IP address
            in_razor_subnet = interface_array.map { |val|
              ip_addr = Facter::Util::IP.get_interface_value(val,'ipaddress')
              # skip to next unless looking at loopback interface or IP address is the same as the razor_server_ip
              next unless val == "lo" || ip_addr == razor_server_ip
              netmask = Facter::Util::IP.get_interface_value(val,'netmask')
              # construct a new IPAddr object from the ip_addr and netmask we just
              # retrieved, then test to see if our remote_addr is in that same subnet
              # (if so, map to true, otherwise map to false)
              internal = IPAddr.new("#{ip_addr}/#{netmask}")
              internal.include?(remote_addr) ? true : false
            }.include?(true)
            # if no match was found, then access to this resource is denied
            unless in_razor_subnet
              env['api.format'] = :text
              error!({ error: "Remote Access Forbidden",
                       detail: "Access to /boot resource is not allowed from outside of the Razor subnet",
                     }, 403)
            end
          end
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
