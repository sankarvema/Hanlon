module ProjectHanlon
    module HttpHelper
  def hnl_http_delete(uri, include_http_response = false)
    # setup the request
    http = Net::HTTP.new(uri.host, uri.port)
    request = Net::HTTP::Delete.new(uri.request_uri)
    # make the request
    response = nil
    begin
      response = http.request(request)
    rescue Errno::ECONNREFUSED
      raise ProjectHanlon::Error::Slice::CommandFailed, "Cannot access Hanlon server at #{uri.to_s.sub(/\/[^\/]+[\/]?$/,'')}"
    end
    # and return the result
    return [JSON.parse(response.body)["response"], response] if include_http_response
    JSON.parse(response.body)["response"]
  end

  def hnl_http_put_json_data(uri, json_data, include_http_response = false)
    # setup the request
    http = Net::HTTP.new(uri.host, uri.port)
    request = Net::HTTP::Put.new(uri.request_uri)
    request.body = json_data
    request["Content-Type"] = "application/json"
    # make the request
    response = nil
    begin
      response = http.request(request)
    rescue Errno::ECONNREFUSED
      raise ProjectHanlon::Error::Slice::CommandFailed, "Cannot access Hanlon server at #{uri.to_s.sub(/\/[^\/]+[\/]?$/,'')}"
    end
    # and return the result
    return [JSON.parse(response.body)["response"], response] if include_http_response
    JSON.parse(response.body)["response"]
  end

  def hnl_http_post_json_data(uri, json_data, include_http_response = false)
    # setup the request
    http = Net::HTTP.new(uri.host, uri.port)
    request = Net::HTTP::Post.new(uri.request_uri)
    request.body = json_data
    request["Content-Type"] = "application/json"
    # make the request
    response = nil
    begin
      response = http.request(request)
    rescue Errno::ECONNREFUSED
      raise ProjectHanlon::Error::Slice::CommandFailed, "Cannot access Hanlon server at #{uri.to_s.sub(/\/[^\/]+[\/]?$/,'')}"
    end
    # and return the result
    return [JSON.parse(response.body)["response"], response] if include_http_response
    JSON.parse(response.body)["response"]
  end

# used to retrieve a result when the endpoint is expected to return
# a JSON hash containing the results as the response (this is used
# in the config slice, for example, who's endpoint returns the configuration
# as a JSON hash in the response body)
  def hnl_http_get_hash_response(uri, include_http_response = false)
    # setup the request
    http = Net::HTTP.new(uri.host, uri.port)
    request = Net::HTTP::Get.new(uri.request_uri)
    # make the request
    response = nil
    begin
      response = http.request(request)
    rescue Errno::ECONNREFUSED
      raise ProjectHanlon::Error::Slice::CommandFailed, "Cannot access Hanlon server at #{uri.to_s.sub(/\/[^\/]+[\/]?$/,'')}"
    end
    # and return the result
    return [JSON.parse(response.body), response] if include_http_response
    JSON.parse(response.body)
  end

# used to retrieve a result when the endpoint is expected
# to return a plain-text response (in which case the response
# body contains the response, not a JSON version of the response)
  def hnl_http_get_text(uri, include_http_response = false)
    # setup the request
    http = Net::HTTP.new(uri.host, uri.port)
    request = Net::HTTP::Get.new(uri.request_uri)
    # make the request
    response = nil
    begin
      response = http.request(request)
    rescue Errno::ECONNREFUSED
      raise ProjectHanlon::Error::Slice::CommandFailed, "Cannot access Hanlon server at #{uri.to_s.sub(/\/[^\/]+[\/]?$/,'')}"
    end
    # and return the result
    return [response.body, response] if include_http_response
    response.body
  end

# used to retrieve a result when the endpoint is expected
# to return a JSON version of a hash map in the response body
# that includes the actual response in the "response" field
# of that hash map (requiring a JSON.parse call followed by
# retrieval of the response field to get the response to return
# to the user)
  def hnl_http_get(uri, include_http_response = false)
    # setup the request
    http = Net::HTTP.new(uri.host, uri.port)
    request = Net::HTTP::Get.new(uri.request_uri)
    # make the request
    response = nil
    begin
      response = http.request(request)
    rescue Errno::ECONNREFUSED
      raise ProjectHanlon::Error::Slice::CommandFailed, "Cannot access Hanlon server at #{uri.to_s.sub(/\/[^\/]+[\/]?$/,'')}"
    end
    # and return the result
    return [JSON.parse(response.body)["response"], response] if include_http_response
    JSON.parse(response.body)["response"]
  end
end
end

