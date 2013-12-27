#

require 'json'

module Razor
  module WebService
    module Image

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

        resource :image do

          # GET /image
          # Query for images.
          get do
            image_slice = ProjectRazor::Slice.new
            Razor::WebService::Response.new(200, 'OK', 'Success.', image_slice.get_object("images", :images))
          end     # end GET /image

          resource '/:path', requirements: { path: /.*/ } do
            # GET /image/{os_type}/{uuid}/{action}/{file}
            # Query for file from an image (by path)
            get do
              path = params[:path]
              filename = path.split(File::SEPARATOR)[-1]
              #content_type "application/octet-stream"
              header['Content-Disposition'] = "attachment; filename=#{filename}"
              env['api.format'] = :binary
              File.read(File.join(PROJECT_ROOT, "image", path))
            end    # end GET /image/{path}

          end    # end resource /image/{path}

        end     # end resource /image

      end

    end

  end

end