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
            string_ =~ /^[A-Za-z0-9]{1,22}$/
          end

          def get_data_ref
            Razor::WebService::Utils::get_data
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

          # POST /image
          # Create a Razor model
          #   parameters:
          #     type      | String | The "type" of image being added                        |    | Default: unavailable
          #     path      | String | The "path" to the image ISO                            |    | Default: unavailable
          #     name      | String | The logical name to use for the image (os images only) |    | Default: unavailable
          #     version   | String | The version to use for the image (os images only)      |    | Default: unavailable
          before do
            # only allow access to this resource from the Razor subnet
            unless request_is_from_razor_subnet(env['REMOTE_ADDR'])
              env['api.format'] = :text
              raise ProjectRazor::Error::Slice::MethodNotAllowed, "Remote Access Forbidden; access to /image/{component} resource is not allowed from outside of the Razor subnet"
            end
          end
          params do
            requires "type", type: String
            requires "path", type: String
            optional "name", type: String
            optional "version", type: String
          end
          post do
            image_type = params["type"]
            iso_path = params["path"]
            os_name = params["name"]
            os_version = params["version"]
            unless ([image_type.to_sym] - SLICE_REF.image_types.keys).size == 0
              raise ProjectRazor::Error::Slice::InvalidImageType, "Invalid Image Type '#{image_type}', valid types are: " +
                  SLICE_REF.image_types.keys.map { |k| k.to_s }.join(', ')
            end
            raise ProjectRazor::Error::Slice::MissingArgument, '[/path/to/iso]' unless iso_path != nil && iso_path != ""
            classname = SLICE_REF.image_types[image_type.to_sym][:classname]
            image = ::Object::full_const_get(classname).new({})
            # We send the new image object to the appropriate method
            res = []
            unless image_type == "os"
              res = SLICE_REF.send SLICE_REF.image_types[image_type.to_sym][:method], image, iso_path,
                                   ProjectRazor.config.image_svc_path
            else
              res = SLICE_REF.send SLICE_REF.image_types[image_type.to_sym][:method], image, iso_path,
                                   ProjectRazor.config.image_svc_path, os_name, os_version
            end
            raise ProjectRazor::Error::Slice::InternalError, res[1] unless res[0]
            raise ProjectRazor::Error::Slice::InternalError, "Could not save image." unless SLICE_REF.insert_image(image)
            slice_success_object(SLICE_REF, :create_image, image, :success_type => :created)
          end     # end POST /image

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
              if is_uuid?(component)
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

            # DELETE /image/{component}
            # Handles DELETE operations for images (by UUID)
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
            delete do
              component = params[:component]
              # test to ensure that the component looks like a UUID (and not the path to a component
              # of the image)
              if is_uuid?(component)
                # it's a UUID, to retrieve the appropriate image and return it
                image_uuid = component
                image = SLICE_REF.get_object("image_with_uuid", :images, image_uuid)
                unless image && (image.class != Array || image.length > 0)
                  raise ProjectRazor::Error::Slice::InvalidUUID, "invalid uuid [#{image_uuid.inspect}]"
                end
                # Use the Engine instance to remove the selected image from the database
                engine = ProjectRazor::Engine.instance
                return_status = false
                begin
                  return_status = engine.remove_image(image)
                rescue RuntimeError => e
                  raise ProjectRazor::Error::Slice::InternalError, e.message
                rescue Exception => e
                  # if got to here, then the Engine raised an exception
                  raise ProjectRazor::Error::Slice::CouldNotRemove, e.message
                end
                slice_success_response(SLICE_REF, :remove_image_by_uuid, "Image [#{image.uuid}] removed", :success_type => :removed)
              else
                raise ProjectRazor::Error::Slice::MethodNotAllowed, "Deletion of components of an image via the RESTful API is no allowed"
              end
            end    # end DELETE /image/{component}

          end    # end resource /image/{component}

        end     # end resource /image

      end

    end

  end

end