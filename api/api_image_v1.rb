#

require 'json'
require 'uri'
require 'api_utils'

module Razor
  module WebService
    module Image

      class APIv1 < Grape::API

        version :v1, :using => :path, :vendor => "razor"
        format :json
        default_format :json
        SLICE_REF = ProjectRazor::Slice::Image.new([])

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

          def request_is_from_razor_subnet(ip_addr)
            Razor::WebService::Utils::request_from_razor_subnet?(ip_addr)
          end

          def slice_success_response(slice, command, response, options = {})
            Razor::WebService::Utils::rz_slice_success_response(slice, command, response, options)
          end

          def slice_success_object(slice, command, response, options = {})
            Razor::WebService::Utils::rz_slice_success_object(slice, command, response, options)
          end

        end

        # the following description hides this endpoint from the swagger-ui-based documentation
        # (since the functionality provided by this endpoint is not intended to be used outside
        # of the razor subnet, or in the case of a GET on the /image resource, off of the Razor
        # server itself)
        desc 'Hide this endpoint', {
            :hidden => true
        }
        resource :image do
          # GET /image
          # Query for images.
          before do
            # only test if directly accessing the /config resource
            if env["PATH_INFO"].match(/image$/)
              # only allow access to configuration resource from the razor server
              unless request_is_from_razor_subnet(env['REMOTE_ADDR'])
                raise ProjectRazor::Error::Slice::MethodNotAllowed, "Remote Access Forbidden; access to /image resource is not allowed from outside of the Razor subnet"
              end
            end
          end
          get do
            images = SLICE_REF.get_object("images", :images)
            slice_success_object(SLICE_REF, :get_all_images, images, :success_type => :created)
          end     # end GET /image

          resource '/:component', requirements: { component: /.*/ } do
            # GET /image/{component}
            # Handles GET operations for images (by UUID) and files from an image (by path)
            before do
              # only allow access to this resource from the Razor subnet
              unless request_is_from_razor_subnet(env['REMOTE_ADDR'])
                env['api.format'] = :text
                raise ProjectRazor::Error::Slice::MethodNotAllowed, "Remote Access Forbidden; access to /image/{component} resource is not allowed from outside of the Razor subnet"
              end
            end
            params do
              requires :component, type: String
            end
            get do
              component = params[:component]
              # test to see if the component looks more like a UUID or a path to a component
              # of the image that the user is interested in
              if /^[^\/]+$/.match(component)
                # it's a UUID, to retrieve the appropriate image and return it
                image_uuid = component
                image = SLICE_REF.get_object("images", :images, image_uuid)
                slice_success_object(SLICE_REF, :get_image_by_uuid, image, :success_type => :generic)
              else
                path = component
                # it's not a UUID, so treat it as a path to a file and return the component
                # of the image that the user is interested in
                filename = path.split(File::SEPARATOR)[-1]
                #content_type "application/octet-stream"
                header['Content-Disposition'] = "attachment; filename=#{filename}"
                env['api.format'] = :binary
                File.read(File.join(PROJECT_ROOT, "image", path))
              end
            end    # end GET /image/{component}

          end    # end resource /image/{component}

        end     # end resource /image

      end

    end

  end

end