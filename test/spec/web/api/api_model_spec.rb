
hnl_uri = ProjectHanlon.config.hanlon_uri + ProjectHanlon.config.websvc_root

describe 'Hanlon::WebService::Model' do

  include SpecHttpHelper

  before(:all) do
    $model_uuid = nil

  end

  describe 'resource :model' do

    describe 'GET /model' do
      it 'Returns a list of all model instances' do
        uri = URI.parse(hnl_uri + '/model')
        # make the request
        response = spec_http_get(uri)
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

        # make the request
        response = spec_http_post_json_data(uri, json_data)
        # parse the output and validate
        parsed = JSON.parse(response.body)
        expect(parsed['resource']).to eq('ProjectHanlon::Slice::Model')
        expect(parsed['command']).to eq('create_model')
        expect(parsed['result']).to eq('Created')
        expect(parsed['http_err_code']).to eq(201)
        expect(parsed['errcode']).to eq(0)
        # save the created UUID for later use
        $model_uuid = parsed['response']['@uuid']
      end
    end   # end POST /model

    describe 'resource :templates' do

      describe 'GET /model/templates' do
        it 'Returns a list of available model templates' do
          uri = URI.parse(hnl_uri + '/model/templates')
          # make the request
          response = spec_http_get(uri)
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

            # make the request
            response = spec_http_get(uri)
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
          uri = URI.parse(hnl_uri + '/model/' + $model_uuid)
          # make the request
          response = spec_http_get(uri)
          # parse the output and validate
          parsed = JSON.parse(response.body)
          expect(parsed['resource']).to eq('ProjectHanlon::Slice::Model')
          expect(parsed['command']).to eq('get_model_by_uuid')
          expect(parsed['result']).to eq('Ok')
          expect(parsed['http_err_code']).to eq(200)
          expect(parsed['errcode']).to eq(0)
          # make sure we are getting the same model
          expect(parsed['response']['@uuid']).to eq($model_uuid)
        end
      end   # end GET /model/{uuid}

      describe 'PUT /model/{uuid}' do
        it 'Updates a model instance (by UUID)' do
          uri = URI.parse(hnl_uri + '/model/' + $model_uuid)

          label = 'new_spec_test_model'

          body_hash = {
              :label => label,
          }
          json_data = body_hash.to_json

          # make the request
          response = spec_http_put_json_data(uri, json_data)
          # parse the output and validate
          parsed = JSON.parse(response.body)
          expect(parsed['resource']).to eq('ProjectHanlon::Slice::Model')
          expect(parsed['command']).to eq('update_model')
          expect(parsed['result']).to eq('Updated')
          expect(parsed['http_err_code']).to eq(202)
          expect(parsed['errcode']).to eq(0)
          # make sure we are updating the label
          expect(parsed['response']['@label']).to eq(label)
        end
      end   # end PUT /model/{uuid}

      describe 'DELETE /model/{uuid}' do
        it 'Removes a model instance (by UUID)' do
          uri = URI.parse(hnl_uri + '/model/' + $model_uuid)
          # make the request
          response = spec_http_delete(uri)
          # parse the output and validate
          parsed = JSON.parse(response.body)
          expect(parsed['resource']).to eq('ProjectHanlon::Slice::Model')
          expect(parsed['command']).to eq('remove_model_by_uuid')
          expect(parsed['result']).to eq('Removed')
          expect(parsed['http_err_code']).to eq(202)
          expect(parsed['errcode']).to eq(0)
          # make sure we are returning the same model uuid
          expect(parsed['response']).to include($model_uuid)
        end
      end   # end DELETE /model/{uuid}

    end   # end resource /:uuid

  end   # end resource :model

end
