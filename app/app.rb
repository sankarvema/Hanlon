#

module Razor
  module WebService
    class App

      def initialize
        if SERVICE_CONFIG[:config][:swagger_ui] && SERVICE_CONFIG[:config][:swagger_ui][:allow_access]

          @filenames = [ '', '.html', 'index.html', '/index.html' ]
          @rack_static = ::Rack::Static.new(
              lambda { [404, {}, []] }, {
              :root => File.expand_path('../../public', __FILE__),
              :urls => %w[/]
          })
        end
      end

      def call(env)
        if SERVICE_CONFIG[:config][:swagger_ui] && SERVICE_CONFIG[:config][:swagger_ui][:allow_access]

          request_path = env['PATH_INFO']

          # in cases where the URL entered by the user ended with a slash,
          # the paths can have a duplicate first directory in the front of
          # the request path.  The following is a hack to deal with that
          # issue (should it arise).  First, parse out the first two
          # "fields" (using the '/' as a separator) using a regex
          match = /^(\/[^\/]+)(\/[^\/]+)(.*)$/.match(request_path)

          # if there was a match, and if the first two fields are identical,
          # then remove the first and keep just the second and third as the
          # new value for the 'request_path'
          if match && match[1] == match[2]
            request_path = match[2] + match[3]
          end

          # check to see if the requested resource can be loaded as a static file
          @filenames.each do |path|
            response = @rack_static.call(env.merge({'PATH_INFO' => request_path + path}))
            return response unless [ 404, 405 ].include?(response[0])
          end
        end

        # if not, then load it via the api
        @@base_uri = env['SCRIPT_NAME']
        Razor::WebService::API.call(env)
      end

      def self.base_uri
        @@base_uri
      end

    end
  end
end
