
hnl_uri = ProjectHanlon.config.hanlon_uri + ProjectHanlon.config.websvc_root

describe 'Hanlon::WebService::ActiveModel' do

  describe 'resource :active_model' do

    describe 'GET /active_model' do

      it 'Returns a list of all active model instances' do
        uri = URI.parse(hnl_uri + '/active_model')
        http_client = Net::HTTP.new(uri.host, uri.port)
        request = Net::HTTP::Get.new(uri.request_uri)
        # make the request
        response = http_client.request(request)
        # parse the output and validate
        parsed = JSON.parse(response.body)
        expect(parsed['resource']).to eq('ProjectHanlon::Slice::ActiveModel')
        expect(parsed['command']).to eq('get_all_active_models')
        expect(parsed['result']).to eq('Ok')
        expect(parsed['http_err_code']).to eq(200)
        expect(parsed['errcode']).to eq(0)

        # TODO - How can we make sure an active model exists in a test environment?
        # Here we expect there is at least one active_model available
        # and we save the UUID so we can test with it below
        $active_model_uuid = parsed['response'][0]['@uuid']

        # This part is just set-up to get the node_uuid and hw_id for testing below
        uri = URI.parse(hnl_uri + '/active_model/' + $active_model_uuid)
        http_client = Net::HTTP.new(uri.host, uri.port)
        request = Net::HTTP::Get.new(uri.request_uri)
        # make the request
        response = http_client.request(request)
        # parse the output and validate
        parsed = JSON.parse(response.body)
        $node_uuid = parsed['response']['@model']['@node']['@uuid']
        $hw_id     = parsed['response']['@model']['@node']['@hw_id'][0]
      end

      it 'Returns an active model instance (by node_uuid)' do
        uri = URI.parse(hnl_uri + '/active_model?node_uuid=' + $node_uuid)
        http_client = Net::HTTP.new(uri.host, uri.port)
        request = Net::HTTP::Get.new(uri.request_uri)
        # make the request
        response = http_client.request(request)
        # parse the output and validate
        parsed = JSON.parse(response.body)
        expect(parsed['resource']).to eq('ProjectHanlon::Slice::ActiveModel')
        expect(parsed['command']).to eq('get_all_active_models')
        expect(parsed['result']).to eq('Ok')
        expect(parsed['http_err_code']).to eq(200)
        expect(parsed['errcode']).to eq(0)
        #make sure we are getting the same active model
        expect(parsed['response']['@uuid']).to eq($active_model_uuid)
      end

      it 'Returns an active model instance (by hw_id)' do
        uri = URI.parse(hnl_uri + '/active_model?hw_id=' + $hw_id)
        http_client = Net::HTTP.new(uri.host, uri.port)
        request = Net::HTTP::Get.new(uri.request_uri)
        # make the request
        response = http_client.request(request)
        # parse the output and validate
        parsed = JSON.parse(response.body)
        expect(parsed['resource']).to eq('ProjectHanlon::Slice::ActiveModel')
        expect(parsed['command']).to eq('get_all_active_models')
        expect(parsed['result']).to eq('Ok')
        expect(parsed['http_err_code']).to eq(200)
        expect(parsed['errcode']).to eq(0)
        #make sure we are getting the same active model
        expect(parsed['response']['@uuid']).to eq($active_model_uuid)
      end

    end   # end GET /active_model

    describe 'DELETE /active_model' do
      # it 'Removes an active model instance (by node_uuid)' do
      #   # TODO - add test to Removes an active model instance (by node_uuid)
      #
      # end
      # it 'Removes an active model instance (by hw_id)' do
      #   # TODO - add test to Removes an active model instance (by hw_id)
      #
      # end
    end   # end DELETE /active_model

    describe 'resource /logs' do

      describe 'GET /active_model/logs' do
        it 'Returns the log entries for all active model instances' do
          uri = URI.parse(hnl_uri + '/active_model/logs')
          http_client = Net::HTTP.new(uri.host, uri.port)
          request = Net::HTTP::Get.new(uri.request_uri)
          # make the request
          response = http_client.request(request)
          # parse the output and validate
          parsed = JSON.parse(response.body)
          expect(parsed['resource']).to eq('ProjectHanlon::Slice::ActiveModel')
          expect(parsed['command']).to eq('get_active_model_logs')
          expect(parsed['result']).to eq('Ok')
          expect(parsed['http_err_code']).to eq(200)
          expect(parsed['errcode']).to eq(0)
        end
      end   # end GET /active_model/logs

    end   # end resource /logs

    describe 'resource /:uuid' do

      describe 'GET /active_model/{uuid}' do
        it 'Returns the details for a specific active model instance (by uuid)' do
          uri = URI.parse(hnl_uri + '/active_model/' + $active_model_uuid)
          http_client = Net::HTTP.new(uri.host, uri.port)
          request = Net::HTTP::Get.new(uri.request_uri)
          # make the request
          response = http_client.request(request)
          # parse the output and validate
          parsed = JSON.parse(response.body)
          expect(parsed['resource']).to eq('ProjectHanlon::Slice::ActiveModel')
          expect(parsed['command']).to eq('get_active_model_by_uuid')
          expect(parsed['result']).to eq('Ok')
          expect(parsed['http_err_code']).to eq(200)
          expect(parsed['errcode']).to eq(0)
        end
      end   # end GET /active_model/{uuid}

      describe 'DELETE /active_model/{uuid}' do
        # it 'Removes an active model instance (by uuid)' do
        #   # TODO - add test to Removes an active model instance (by uuid)
        #
        # end
      end   # end DELETE /active_model/{uuid}

      describe 'resource /logs' do
        describe 'GET /active_model/{uuid}/logs' do
          it 'Returns the log entries for a specific active model instance (by uuid)' do
            uri = URI.parse(hnl_uri + '/active_model/' + $active_model_uuid + '/logs')
            http_client = Net::HTTP.new(uri.host, uri.port)
            request = Net::HTTP::Get.new(uri.request_uri)
            # make the request
            response = http_client.request(request)
            # parse the output and validate
            parsed = JSON.parse(response.body)
            expect(parsed['resource']).to eq('ProjectHanlon::Slice::ActiveModel')
            expect(parsed['command']).to eq('get_active_model_logs')
            expect(parsed['result']).to eq('Ok')
            expect(parsed['http_err_code']).to eq(200)
            expect(parsed['errcode']).to eq(0)
          end
        end   # end GET /active_model/{uuid}/logs
      end   # end resource /logs

    end   # end resource /:uuid

  end   # end resource :active_model

end
