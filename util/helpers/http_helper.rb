module ProjectHanlon
  module HttpHelper

    def hnl_http_delete(uri, include_http_response = false)
      # setup the request
      http_client = Net::HTTP.new(uri.host, uri.port)
      request = Net::HTTP::Delete.new(uri.request_uri)
      # make the request
      response = make_http_request(uri, http_client, request)
      # and return the result
      handle_http_response(uri, response, include_http_response)
    end

    def hnl_http_put_json_data(uri, json_data, include_http_response = false)
      # setup the request
      http_client = Net::HTTP.new(uri.host, uri.port)
      request = Net::HTTP::Put.new(uri.request_uri)
      request.body = json_data
      request["Content-Type"] = "application/json"
      # make the request
      response = make_http_request(uri, http_client, request)
      # and return the result
      handle_http_response(uri, response, include_http_response)
    end

    def hnl_http_post_json_data(uri, json_data, include_http_response = false)
      # setup the request
      http_client = Net::HTTP.new(uri.host, uri.port)
      http_client.read_timeout = ProjectHanlon.config.http_timeout
      request = Net::HTTP::Post.new(uri.request_uri)
      request.body = json_data
      request["Content-Type"] = "application/json"
      # make the request
      response = make_http_request(uri, http_client, request)
      # and return the result
      handle_http_response(uri, response, include_http_response)
    end

    # used to retrieve a result when the endpoint is expected
    # to return a JSON version of a hash map in the response body
    # that includes the actual response in the "response" field
    # of that hash map (requiring a JSON.parse call followed by
    # retrieval of the response field to get the response to return
    # to the user)
    def hnl_http_get(uri, include_http_response = false)
      # setup the request
      http_client = Net::HTTP.new(uri.host, uri.port)
      request = Net::HTTP::Get.new(uri.request_uri)
      # make the request
      response = make_http_request(uri, http_client, request)
      # and return the result
      handle_http_response(uri, response, include_http_response)
    end

    private

    def make_http_request(uri, http_client, request)
      begin
        response = http_client.request(request)
      rescue Errno::ECONNREFUSED, Errno::EHOSTUNREACH => e
        raise ProjectHanlon::Error::Slice::CommandFailed, "Cannot access Hanlon server at #{uri.to_s.sub(/\/[^\/]+[\/]?$/,'')}"
      rescue StandardError => e
        raise ProjectHanlon::Error::Slice::CommandFailed, "Error while submitting request #{request} against uri #{uri}\n\t#{e.inspect}"
      end
    end

    def handle_http_response(uri, response, include_http_response)
      case response
        when Net::HTTPSuccess
          return [get_hnl_response(response), response] if include_http_response
          get_hnl_response(response)
        when Net::HTTPNotFound
          raise ProjectHanlon::Error::Slice::CommandFailed, "Cannot access Hanlon server at #{uri.to_s.sub(/\/[^\/]+[\/]?$/,'')}"
        when Net::HTTPForbidden, Net::HTTPBadRequest, Net::HTTPInternalServerError
          raise ProjectHanlon::Error::Slice::CommandFailed, get_hnl_response(response)["result"]["description"]
        else
          raise ProjectHanlon::Error::Slice::CommandFailed, response.message
      end
    end

    def get_hnl_response(http_response)
      # first, try to parse the body of the response as a JSON string; if that doesn't
      # work then return the body of the response (as text) instead
      begin
        JSON.parse(http_response.body)["response"]
      rescue JSON::ParserError => e
        http_response.body
      end
    end

  end
end

