#

require 'json'
require 'api_utils'

module Razor
  module WebService
    module Config

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

        rescue_from ProjectRazor::Error::Slice::MethodNotAllowed do |e|
          Rack::Response.new(
              Razor::WebService::Response.new(403, e.class.name, e.message).to_json,
              403,
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

          def request_is_from_razor_server(ip_addr)
            Razor::WebService::Utils::request_from_razor_server?(ip_addr)
          end

        end

        # the following description hides this endpoint from the swagger-ui-based documentation
        # (since the functionality provided by this endpoint is not intended to be used off of
        # the Razor server)
        desc 'Hide this endpoint', {
            :hidden => true
        }
        resource :config do

          # GET /config
          # Query for Razor server configuration
          before do
            # only test if directly accessing the /config resource
            if env["PATH_INFO"].match(/config$/)
              # only allow access to configuration resource from the razor server
              unless request_is_from_razor_server(env['REMOTE_ADDR'])
                raise ProjectRazor::Error::Slice::MethodNotAllowed, "Remote Access Forbidden; access to /config resource is only allowed from Razor server"
              end
            end
          end
          get do
            JSON(ProjectRazor.config.to_hash.to_json)
          end     # end GET /config

          resource :ipxe do
            # GET /config/ipxe
            # Query for iPXE boot script to use (from Microkernel)
            before do
              # only allow access to configuration resource from the razor server
              unless request_is_from_razor_server(env['REMOTE_ADDR'])
                env['api.format'] = :text
                raise ProjectRazor::Error::Slice::MethodNotAllowed, "Remote Access Forbidden; access to /config/ipxe resource is only allowed from Razor server"
              end
            end
            get do
              @ipxe_options = {}
              @ipxe_options[:style] = :new
              @ipxe_options[:uri] =  ProjectRazor.config.mk_uri
              @ipxe_options[:timeout_sleep] = IPXE_TIMEOUT
              @ipxe_options[:nic_max] = IPXE_NIC_MAX
              env['api.format'] = :text
              ERB.new(File.read(IPXE_ERB)).result(binding)
            end     # end GET /config/ipxe

          end     # end resource /config/ipxe

        end     # end resource /config

      end

    end

  end

end
