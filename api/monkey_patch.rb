#

module Grape
  module Middleware
    class Error

      def endpoint_api_format
        env['api.endpoint'].api_format
      end

      def endpoint_content_type
        env['api.endpoint'].settings[:content_types]
      end

      def content_type_header
        endpoint_content_type[endpoint_api_format]
      end

    end
  end
end