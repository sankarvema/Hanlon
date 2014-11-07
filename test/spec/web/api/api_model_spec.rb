
hnl_uri = ProjectHanlon.config.hanlon_uri + ProjectHanlon.config.websvc_root

describe 'Hanlon::WebService::Model' do

  describe 'resource :model' do

    describe 'GET /model' do
      it 'Returns a list of all model instances' do
        uri = URI.parse(hnl_uri + '/model')
        http_client = Net::HTTP.new(uri.host, uri.port)
        request = Net::HTTP::Get.new(uri.request_uri)
        # make the request
        response = http_client.request(request)
        # parse the output and validate
        parsed = JSON.parse(response.body)
        expect(parsed['resource']).to eq('ProjectHanlon::Slice::Model')
        expect(parsed['command']).to eq('get_all_models')
        expect(parsed['result']).to eq('Ok')
        expect(parsed['http_err_code']).to eq(200)
        expect(parsed['errcode']).to eq(0)
      end
    end   # end GET /model

    describe 'POST /model' do
      it 'Creates a new model instance' do
        uri = URI.parse(hnl_uri + '/model')

        template = 'discover_only'
        label = 'spec_test_model'

        body_hash = {
            :template => template,
            :label => label,
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
        expect(parsed['resource']).to eq('ProjectHanlon::Slice::Model')
        expect(parsed['command']).to eq('create_model')
        expect(parsed['result']).to eq('Created')
        expect(parsed['http_err_code']).to eq(201)
        expect(parsed['errcode']).to eq(0)
        # save the created UUID for later use
        response_hash = parsed['response']
        $spec_uuid = response_hash['@uuid']
      end
    end   # end POST /model

    describe 'resource :templates' do

      describe 'GET /model/templates' do
        it 'Returns a list of available model templates' do
          uri = URI.parse(hnl_uri + '/model/templates')
          http_client = Net::HTTP.new(uri.host, uri.port)
          request = Net::HTTP::Get.new(uri.request_uri)
          # make the request
          response = http_client.request(request)
          # parse the output and validate
          parsed = JSON.parse(response.body)
          expect(parsed['resource']).to eq('ProjectHanlon::Slice::Model')
          expect(parsed['command']).to eq('get_model_templates')
          expect(parsed['result']).to eq('Ok')
          expect(parsed['http_err_code']).to eq(200)
          expect(parsed['errcode']).to eq(0)
        end
      end   # end GET /model/templates

      describe 'resource /:name' do
        describe 'GET /model/templates/{name}' do
          it 'Returns details for a specific model template (by name)' do

            template = 'discover_only'

            uri = URI.parse(hnl_uri + '/model/templates/' + template)

            http_client = Net::HTTP.new(uri.host, uri.port)
            request = Net::HTTP::Get.new(uri.request_uri)
            # make the request
            response = http_client.request(request)
            # parse the output and validate
            parsed = JSON.parse(response.body)
            expect(parsed['resource']).to eq('ProjectHanlon::Slice::Model')
            expect(parsed['command']).to eq('get_model_template_by_uuid')
            expect(parsed['result']).to eq('Ok')
            expect(parsed['http_err_code']).to eq(200)
            expect(parsed['errcode']).to eq(0)
          end
        end   # end GET /model/templates/{name}
      end   # end resource /:name

    end   # end resource :templates

    describe 'resource /:uuid' do

      describe 'GET /model/{uuid}' do
        it 'Returns details for a specific model instance (by UUID)' do
          uri = URI.parse(hnl_uri + '/model/' + $spec_uuid)
          http_client = Net::HTTP.new(uri.host, uri.port)
          request = Net::HTTP::Get.new(uri.request_uri)
          # make the request
          response = http_client.request(request)
          # parse the output and validate
          parsed = JSON.parse(response.body)
          expect(parsed['resource']).to eq('ProjectHanlon::Slice::Model')
          expect(parsed['command']).to eq('get_model_by_uuid')
          expect(parsed['result']).to eq('Ok')
          expect(parsed['http_err_code']).to eq(200)
          expect(parsed['errcode']).to eq(0)
        end
      end   # end GET /model/{uuid}

      describe 'PUT /model/{uuid}' do
        it 'Updates a model instance (by UUID)' do
          uri = URI.parse(hnl_uri + '/model/' + $spec_uuid)

          label = 'new_spec_test_model'

          body_hash = {
              :label => label,
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
          expect(parsed['resource']).to eq('ProjectHanlon::Slice::Model')
          expect(parsed['command']).to eq('update_model')
          expect(parsed['result']).to eq('Updated')
          expect(parsed['http_err_code']).to eq(202)
          expect(parsed['errcode']).to eq(0)
        end
      end   # end PUT /model/{uuid}

      describe 'DELETE /model/{uuid}' do
        it 'Removes a model instance (by UUID)' do
          uri = URI.parse(hnl_uri + '/model/' + $spec_uuid)
          http_client = Net::HTTP.new(uri.host, uri.port)
          request = Net::HTTP::Delete.new(uri.request_uri)
          # make the request
          response = http_client.request(request)
          # parse the output and validate
          parsed = JSON.parse(response.body)
          expect(parsed['resource']).to eq('ProjectHanlon::Slice::Model')
          expect(parsed['command']).to eq('remove_model_by_uuid')
          expect(parsed['result']).to eq('Removed')
          expect(parsed['http_err_code']).to eq(202)
          expect(parsed['errcode']).to eq(0)
        end
      end   # end DELETE /model/{uuid}

    end   # end resource /:uuid

  end   # end resource :model

end
