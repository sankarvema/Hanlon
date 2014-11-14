
module SpecHttpHelper

  def spec_http_get (uri)
    # setup the request
    http_client = Net::HTTP.new(uri.host, uri.port)
    request = Net::HTTP::Get.new(uri.request_uri)
    # make the request
    response = make_http_request(uri, http_client, request)
    # and return the result
    handle_http_response(uri, response)
  end

  def spec_http_post_json_data(uri, json_data)
    # setup the request
    http_client = Net::HTTP.new(uri.host, uri.port)
    http_client.read_timeout = ProjectHanlon.config.http_timeout
    request = Net::HTTP::Post.new(uri.request_uri)
    request.body = json_data
    request['Content-Type'] = 'application/json'
    # make the request
    response = make_http_request(uri, http_client, request)
    # and return the result
    handle_http_response(uri, response)
  end

  def spec_http_put_json_data(uri, json_data)
    # setup the request
    http_client = Net::HTTP.new(uri.host, uri.port)
    request = Net::HTTP::Put.new(uri.request_uri)
    request.body = json_data
    request['Content-Type'] = 'application/json'
    # make the request
    response = make_http_request(uri, http_client, request)
    # and return the result
    handle_http_response(uri, response)
  end

  def spec_http_delete(uri)
    # setup the request
    http_client = Net::HTTP.new(uri.host, uri.port)
    request = Net::HTTP::Delete.new(uri.request_uri)
    # make the request
    response = make_http_request(uri, http_client, request)
    # and return the result
    handle_http_response(uri, response)
  end

  private

  def make_http_request(uri, http_client, request)
    begin
      http_client.request(request)
    rescue Errno::ECONNREFUSED, Errno::EHOSTUNREACH
      raise "Cannot access Hanlon server at #{uri.to_s.sub(/\/[^\/]+[\/]?$/,'')}"
    rescue StandardError => e
      raise "Error while submitting request #{request} against uri #{uri}\n\t#{e.inspect}"
    end
  end

  def handle_http_response(uri, response)
    case response
      when Net::HTTPSuccess
        response
      when Net::HTTPNotFound
        raise "Cannot access Hanlon server at #{uri.to_s.sub(/\/[^\/]+[\/]?$/,'')}"
      when Net::HTTPForbidden, Net::HTTPBadRequest, Net::HTTPInternalServerError
        raise JSON.parse(response.body)['response']['result']['description']
      else
        raise response.message
    end
  end

end