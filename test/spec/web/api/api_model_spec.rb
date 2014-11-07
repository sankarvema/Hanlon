
hnl_uri = ProjectHanlon.config.hanlon_uri + ProjectHanlon.config.websvc_root

describe 'Hanlon::WebService::Model' do

  describe 'resource :model' do

    describe 'GET /model' do
      it 'Returns a list of all model instances' do
        uri = URI.parse(hnl_uri + '/model')
        http_client = Net::HTTP.new(uri.host, uri.port)
        request = Net::HTTP::Get.new(uri.request_uri)
        response = http_client.request(request)
        parsed = JSON.parse(response.body)
        expect(parsed['resource']).to eq('ProjectHanlon::Slice::Model')
        expect(parsed['command']).to eq('get_all_models')
        expect(parsed['result']).to eq('Ok')
        expect(parsed['http_err_code']).to eq(200)
        expect(parsed['errcode']).to eq(0)
        # expect((parsed['response']).size).to eq(3)  # Add something here once we have a known test
      end
    end   # end GET /model

    describe 'POST /model' do
      it 'Creates a new model instance' do
        # ...
        expect(:actual).to be(:expected)
      end
    end   # end POST /model

    describe 'resource :templates' do

      describe 'GET /model/templates' do
        it 'Returns a list of available model templates' do
          uri = URI.parse(hnl_uri + '/model/templates')
          http_client = Net::HTTP.new(uri.host, uri.port)
          request = Net::HTTP::Get.new(uri.request_uri)
          response = http_client.request(request)
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
            # ...
            expect(:actual).to be(:expected)
          end
        end   # end GET /model/templates/{name}
      end   # end resource /:name

    end   # end resource :templates

    describe 'resource /:uuid' do

      describe 'GET /model/{uuid}' do
        it 'Returns details for a specific model instance (by UUID)' do
          # ...
          expect(:actual).to be(:expected)
        end
      end   # end GET /model/{uuid}

      describe 'PUT /model/{uuid}' do
        it 'Updates a model instance (by UUID)' do
          # ...
          expect(:actual).to be(:expected)
        end
      end   # end PUT /model/{uuid}

      describe 'DELETE /model/{uuid}' do
        it 'Removes a model instance (by UUID)' do
          # ...
          expect(:actual).to be(:expected)
        end
      end   # end DELETE /model/{uuid}

    end   # end resource /:uuid

  end   # end resource :model

end
