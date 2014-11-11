
hnl_uri = ProjectHanlon.config.hanlon_uri + ProjectHanlon.config.websvc_root

describe 'Hanlon::WebService::Model' do

  describe 'resource :config' do

    describe 'GET /config' do
      it 'Returns the current Hanlon server configuration' do
        uri = URI.parse(hnl_uri + '/config')
        http_client = Net::HTTP.new(uri.host, uri.port)
        request = Net::HTTP::Get.new(uri.request_uri)
        # make the request
        response = http_client.request(request)
        # parse the output and validate
        parsed = JSON.parse(response.body)
        expect(parsed['resource']).to eq('ProjectHanlon::Slice::Config')
        expect(parsed['command']).to eq('get_config')
        expect(parsed['result']).to eq('Ok')
        expect(parsed['http_err_code']).to eq(200)
        expect(parsed['errcode']).to eq(0)

        # check one of the config items to make sure we are getting a good server config
        response_hash = parsed['response']
        expect(response_hash['@persist_dbname']).to_not eq(nil)
      end
    end

    describe 'resource :ipxe' do

      describe 'GET /config/ipxe' do
        it 'Returns the iPXE-bootstrap script to use (with Hanlon)' do
          uri = URI.parse(hnl_uri + '/config/ipxe')
          http_client = Net::HTTP.new(uri.host, uri.port)
          request = Net::HTTP::Get.new(uri.request_uri)
          # make the request
          response = http_client.request(request)
          # parse the output and validate
          # the response should be a string which begins with #!ipxe
          expect(response.body.start_with?('#!ipxe')).to eq(true)
        end
      end

    end

  end

end
