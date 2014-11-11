
hnl_uri = ProjectHanlon.config.hanlon_uri + ProjectHanlon.config.websvc_root

describe 'Hanlon::WebService::Node' do

  describe 'resource :node' do

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

        # Removing this section until we have methods to dynamically create nodes
        # # TODO - How can we make sure a node exists in a test environment?
        # # Here we expect there is at least one node available
        # # and we save the UUID so we can test with it below
        # $node_uuid = parsed['response'][0]['@uuid']
      end

      # TODO - what is going on in the API here with the UUID and hw_id?

    end   # end GET /node

    describe 'resource :power' do

      describe 'GET /node/power' do
        # it 'Returns the power state of a node (by hw_id)' do
        #   # TODO
        #
        # end
      end   # end GET /node/power

      describe 'POST /node/power' do
        # it 'Resets the power state of a node (by hw_id)' do
        #   # TODO
        #
        # end
      end   # end POST /node/power

    end   # end resource :power

    describe 'resource :checkin' do
      describe 'GET /node/checkin' do
        # it 'Handles a node checkin (by a Microkernel instance)' do
        #   # TODO
        #
        # end
      end   # end GET /node/checkin
    end   # end resource :checkin

    describe 'resource :register' do
      describe 'POST /node/register' do
        # it 'Handles a node registration request (by a Microkernel instance)' do
        #   # TODO
        #
        # end
      end   # end POST /node/register
    end   # end resource :register

    describe 'resource /:uuid' do

      describe 'GET /node/{uuid}' do
        # TODO - Removing this section until we have methods to dynamically create nodes
        # it 'Returns the details for a specific node (by uuid)' do
        #   uri = URI.parse(hnl_uri + '/node/' + $node_uuid)
        #   http_client = Net::HTTP.new(uri.host, uri.port)
        #   request = Net::HTTP::Get.new(uri.request_uri)
        #   # make the request
        #   response = http_client.request(request)
        #   # parse the output and validate
        #   parsed = JSON.parse(response.body)
        #   expect(parsed['resource']).to eq('ProjectHanlon::Slice::Node')
        #   expect(parsed['command']).to eq('get_node_by_uuid')
        #   expect(parsed['result']).to eq('Ok')
        #   expect(parsed['http_err_code']).to eq(200)
        #   expect(parsed['errcode']).to eq(0)
        #   # make sure we are getting the same node
        #   expect(parsed['response']['@uuid']).to eq($node_uuid)
        # end
      end   # end GET /node/{uuid}

      describe 'resource :power' do

        describe 'GET /node/{uuid}/power' do
          # it 'Returns the power state of a specific node (by uuid)' do
          #   # TODO
          #
          # end
        end   # end GET /node/{uuid}/power

        describe 'POST /node/{uuid}/power' do
          # it 'Resets the power state of a specific node (by uuid)' do
          #   # TODO
          #
          # end
        end   # end POST /node/{uuid}/power

      end   # end resource :power

    end   # end resource /:uuid

  end   # end resource :node

end
