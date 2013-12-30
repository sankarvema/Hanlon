#

require 'json'
require 'socket'

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

        resource :config do

          # GET /config
          # Query for Razor server configuration
          after_validation do
            # only test if directly accessing the /config resource
            if env["PATH_INFO"].match(/config$/)
              # only allow access to configuration resource from the localhost
              if !Socket.ip_address_list.map{|val| val.ip_address}.include?(env['REMOTE_ADDR'])
                error!({ error: "Remote Access Forbidden",
                         detail: "Access to /config resource is only allowed from Razor server",
                       }, 403)
              end
            end
          end
          get do
            JSON(ProjectRazor.config.to_hash.to_json)
          end     # end GET /config

          resource :ipxe do
            # GET /config/ipxe
            # Query for iPXE boot script to use (from Microkernel)
            after_validation do
              # only allow access to configuration resource from the localhost
              if !Socket.ip_address_list.map{|val| val.ip_address}.include?(env['REMOTE_ADDR'])
                env['api.format'] = :text
                error!({ error: "Remote Access Forbidden",
                         detail: "Access to /config/ipxe resource is only allowed from Razor server",
                       }, 403)
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

          end       # end resource /config/ipxe

        end         # end resource /model

      end

    end

  end

end
