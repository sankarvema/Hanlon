
hnl_uri = ProjectHanlon.config.hanlon_uri + ProjectHanlon.config.websvc_root

describe 'Hanlon::WebService::Node' do

  before(:all) do
    $hw_id = "TEST#{rand(9)}#{rand(9)}#{rand(9)}#{rand(9)}#{rand(9)}#{rand(9)}#{rand(9)}"
  end

  describe 'resource :node' do

    # Moved this endpoint to the top of the test order to have a node for testing
    describe 'resource :register' do
      describe 'POST /node/register' do
        it 'Handles a node registration request (by a Microkernel instance)' do
          uri = URI.parse(hnl_uri + '/node/register')

          uuid = $hw_id
          last_state = 'idle'
          attributes_hash = {
              :hostname => 'hanlon.example.com',
              :ip_address => '1.1.1.1'
          }

          body_hash = {
              :uuid => uuid,
              :last_state => last_state,
              :attributes_hash => attributes_hash,
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
          expect(parsed['resource']).to eq('ProjectHanlon::Slice::Node')
          expect(parsed['command']).to eq('register_node')
          expect(parsed['result']).to eq('Ok')
          expect(parsed['http_err_code']).to eq(200)
          expect(parsed['errcode']).to eq(0)
          # make sure we are getting the same hw_id in return
          expect(parsed['response']['@hw_id']).to include($hw_id)
          # save the created UUID for later use
          $node_uuid = parsed['response']['@uuid']
        end
      end   # end POST /node/register
    end   # end resource :register

    describe 'GET /node' do
      it 'Returns a list of all node instances' do
        uri = URI.parse(hnl_uri + '/node')
        http_client = Net::HTTP.new(uri.host, uri.port)
        request = Net::HTTP::Get.new(uri.request_uri)
        # make the request
        response = http_client.request(request)
        # parse the output and validate
        parsed = JSON.parse(response.body)
        expect(parsed['resource']).to eq('ProjectHanlon::Slice::Node')
        expect(parsed['command']).to eq('get_all_nodes')
        expect(parsed['result']).to eq('Ok')
        expect(parsed['http_err_code']).to eq(200)
        expect(parsed['errcode']).to eq(0)
      end

    end   # end GET /node

    describe 'resource :power' do

      describe 'GET /node/power' do
        # it 'Returns the power state of a node (by hw_id)' do
        #   # TODO - 'resource :power' not yet implemented
        #
        # end
      end   # end GET /node/power

      describe 'POST /node/power' do
        # it 'Resets the power state of a node (by hw_id)' do
        #   # TODO - 'resource :power' not yet implemented
        #
        # end
      end   # end POST /node/power

    end   # end resource :power

    describe 'resource :checkin' do
      describe 'GET /node/checkin' do
        it 'Handles a node checkin (by a Microkernel instance)' do
          uri = URI.parse(hnl_uri + "/node/checkin?hw_id=#{$hw_id}&last_state=idle_test")
          http_client = Net::HTTP.new(uri.host, uri.port)
          request = Net::HTTP::Get.new(uri.request_uri)
          # make the request
          response = http_client.request(request)
          # parse the output and validate
          parsed = JSON.parse(response.body)
          expect(parsed['resource']).to eq('ProjectHanlon::Slice::Node')
          expect(parsed['command']).to eq('checkin_node')
          expect(parsed['result']).to eq('Ok')
          expect(parsed['http_err_code']).to eq(200)
          expect(parsed['errcode']).to eq(0)
          expect(parsed['response']['command_name']).to eq('acknowledge')
        end
      end   # end GET /node/checkin
    end   # end resource :checkin

    # resource :register goes here in hierarchy but was moved to the top to create a node for testing

    describe 'resource /:uuid' do

      describe 'GET /node/{uuid}' do
        it 'Returns the details for a specific node (by uuid)' do
          uri = URI.parse(hnl_uri + '/node/' + $node_uuid)
          http_client = Net::HTTP.new(uri.host, uri.port)
          request = Net::HTTP::Get.new(uri.request_uri)
          # make the request
          response = http_client.request(request)
          # parse the output and validate
          parsed = JSON.parse(response.body)
          expect(parsed['resource']).to eq('ProjectHanlon::Slice::Node')
          expect(parsed['command']).to eq('get_node_by_uuid')
          expect(parsed['result']).to eq('Ok')
          expect(parsed['http_err_code']).to eq(200)
          expect(parsed['errcode']).to eq(0)
          # make sure we are getting the same node
          expect(parsed['response']['@uuid']).to eq($node_uuid)
        end
      end   # end GET /node/{uuid}

      describe 'resource :power' do

        describe 'GET /node/{uuid}/power' do
          # it 'Returns the power state of a specific node (by uuid)' do
          #   # TODO - 'resource :power' not yet implemented
          #
          # end
        end   # end GET /node/{uuid}/power

        describe 'POST /node/{uuid}/power' do
          # it 'Resets the power state of a specific node (by uuid)' do
          #   # TODO - 'resource :power' not yet implemented
          #
          # end
        end   # end POST /node/{uuid}/power

      end   # end resource :power

    end   # end resource /:uuid

  end   # end resource :node

end
