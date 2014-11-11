
hnl_uri = ProjectHanlon.config.hanlon_uri + ProjectHanlon.config.websvc_root

describe 'Hanlon::WebService::Broker' do

  describe 'resource :broker' do

    describe 'GET /broker' do
      it 'Returns a list of all broker instances' do
        uri = URI.parse(hnl_uri + '/broker')
        http_client = Net::HTTP.new(uri.host, uri.port)
        request = Net::HTTP::Get.new(uri.request_uri)
        # make the request
        response = http_client.request(request)
        # parse the output and validate
        parsed = JSON.parse(response.body)
        expect(parsed['resource']).to eq('ProjectHanlon::Slice::Broker')
        expect(parsed['command']).to eq('get_all_brokers')
        expect(parsed['result']).to eq('Ok')
        expect(parsed['http_err_code']).to eq(200)
        expect(parsed['errcode']).to eq(0)
      end
    end   # end GET /broker

    describe 'POST /broker' do
      it 'Creates a new broker instance' do
        uri = URI.parse(hnl_uri + '/broker')

        plugin = 'puppet'
        name = 'spec_test_broker'
        description = 'spec test puppet broker'

        body_hash = {
            :plugin => plugin,
            :name => name,
            :description => description,
            :req_metadata_params => {},
        }
        json_data = body_hash.to_json

        http_client = Net::HTTP.new(uri.host, uri.port)
        http_client.read_timeout = ProjectHanlon.config.http_timeout
        request = Net::HTTP::Post.new(uri.request_uri)
        request.body = json_data
        request['Content-Type'] = 'application/json'
        # make the request
        response = http_client.request(request)
        # parse the output and validate
        parsed = JSON.parse(response.body)
        expect(parsed['resource']).to eq('ProjectHanlon::Slice::Broker')
        expect(parsed['command']).to eq('create_broker')
        expect(parsed['result']).to eq('Created')
        expect(parsed['http_err_code']).to eq(201)
        expect(parsed['errcode']).to eq(0)
        # save the created UUID for later use
        $broker_uuid = parsed['response']['@uuid']
      end
    end   # end POST /broker

    describe 'resource :plugins' do

      describe 'GET /broker/plugins' do
        it 'Returns a list of available broker plugins' do
          uri = URI.parse(hnl_uri + '/broker/plugins')
          http_client = Net::HTTP.new(uri.host, uri.port)
          request = Net::HTTP::Get.new(uri.request_uri)
          # make the request
          response = http_client.request(request)
          # parse the output and validate
          parsed = JSON.parse(response.body)
          expect(parsed['resource']).to eq('ProjectHanlon::Slice::Broker')
          expect(parsed['command']).to eq('get_broker_plugins')
          expect(parsed['result']).to eq('Ok')
          expect(parsed['http_err_code']).to eq(200)
          expect(parsed['errcode']).to eq(0)
        end
      end   # end GET /broker/plugins

      describe 'resource /:name' do
        describe 'GET /broker/plugins/{name}' do
          it 'Returns details for a specific broker plugin (by name)' do

            broker = 'puppet'

            uri = URI.parse(hnl_uri + '/broker/plugins/' + broker)

            http_client = Net::HTTP.new(uri.host, uri.port)
            request = Net::HTTP::Get.new(uri.request_uri)
            # make the request
            response = http_client.request(request)
            # parse the output and validate
            parsed = JSON.parse(response.body)
            expect(parsed['resource']).to eq('ProjectHanlon::Slice::Broker')
            expect(parsed['command']).to eq('get_broker_plugin_by_uuid')
            expect(parsed['result']).to eq('Ok')
            expect(parsed['http_err_code']).to eq(200)
            expect(parsed['errcode']).to eq(0)
          end
        end   # end GET /broker/plugins/{name}
      end   # end resource /:name
    end   # end resource :plugins

    describe 'resource /:uuid' do

      describe 'GET /broker/{uuid}' do
        it 'Returns details for a specific broker instance (by UUID)' do
          uri = URI.parse(hnl_uri + '/broker/' + $broker_uuid)
          http_client = Net::HTTP.new(uri.host, uri.port)
          request = Net::HTTP::Get.new(uri.request_uri)
          # make the request
          response = http_client.request(request)
          # parse the output and validate
          parsed = JSON.parse(response.body)
          expect(parsed['resource']).to eq('ProjectHanlon::Slice::Broker')
          expect(parsed['command']).to eq('get_broker_by_uuid')
          expect(parsed['result']).to eq('Ok')
          expect(parsed['http_err_code']).to eq(200)
          expect(parsed['errcode']).to eq(0)
          # make sure we are getting the same broker
          expect(parsed['response']['@uuid']).to eq($broker_uuid)
        end
      end   # end GET /broker/{uuid}

      describe 'PUT /broker/{uuid' do
        it 'Updates a broker instance (by UUID)' do
          uri = URI.parse(hnl_uri + '/broker/' + $broker_uuid)

          name = 'new_spec_test_broker'

          body_hash = {
              :name => name,
          }
          json_data = body_hash.to_json

          http_client = Net::HTTP.new(uri.host, uri.port)
          http_client.read_timeout = ProjectHanlon.config.http_timeout
          request = Net::HTTP::Put.new(uri.request_uri)
          request.body = json_data
          request['Content-Type'] = 'application/json'
          # make the request
          response = http_client.request(request)
          # parse the output and validate
          parsed = JSON.parse(response.body)
          expect(parsed['resource']).to eq('ProjectHanlon::Slice::Broker')
          expect(parsed['command']).to eq('update_broker')
          expect(parsed['result']).to eq('Updated')
          expect(parsed['http_err_code']).to eq(202)
          expect(parsed['errcode']).to eq(0)
          # make sure we are updating the name
          expect(parsed['response']['@name']).to eq(name)
        end
      end   # end PUT /broker/{uuid}

      describe 'DELETE /broker/{uuid' do
        it 'Removes a broker instance (by UUID)' do
          uri = URI.parse(hnl_uri + '/broker/' + $broker_uuid)
          http_client = Net::HTTP.new(uri.host, uri.port)
          request = Net::HTTP::Delete.new(uri.request_uri)
          # make the request
          response = http_client.request(request)
          # parse the output and validate
          parsed = JSON.parse(response.body)
          expect(parsed['resource']).to eq('ProjectHanlon::Slice::Broker')
          expect(parsed['command']).to eq('remove_broker_by_uuid')
          expect(parsed['result']).to eq('Removed')
          expect(parsed['http_err_code']).to eq(202)
          expect(parsed['errcode']).to eq(0)
          # make sure we are returning the same broker uuid
          expect(parsed['response']).to include($broker_uuid)
        end
      end   # end DELETE /broker/{uuid}

    end   # end resource /:uuid

  end   # end resource :broker


end

