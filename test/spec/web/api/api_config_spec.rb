
hnl_uri = ProjectHanlon.config.hanlon_uri + ProjectHanlon.config.websvc_root

describe 'Hanlon::WebService::Config' do

  include ProjectHanlon::HttpHelper

  describe 'resource :config' do

    describe 'GET /config' do
      it 'Returns the current Hanlon server configuration' do
        uri = URI.parse(hnl_uri + '/config')
        # make the request
        hnl_response, http_response = hnl_http_get(uri, true)
        # parse the output and validate
        parsed = JSON.parse(http_response.body)
        expect(parsed['resource']).to eq('ProjectHanlon::Slice::Config')
        expect(parsed['command']).to eq('get_config')
        expect(parsed['result']).to eq('Ok')
        expect(parsed['http_err_code']).to eq(200)
        expect(parsed['errcode']).to eq(0)

        # check one of the config items to make sure we are getting a good server config
        expect(hnl_response['@persist_dbname']).to_not eq(nil)
      end
    end

    describe 'resource :ipxe' do

      describe 'GET /config/ipxe' do
        it 'Returns the iPXE-bootstrap script to use (with Hanlon)' do
          uri = URI.parse(hnl_uri + '/config/ipxe')
          # make the request
          http_response = hnl_http_get(uri)
          # parse the output and validate
          # the response should be a string which begins with #!ipxe
          expect(http_response.start_with?('#!ipxe')).to eq(true)
        end
      end

    end

  end

end
