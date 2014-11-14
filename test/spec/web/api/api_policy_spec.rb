
hnl_uri = ProjectHanlon.config.hanlon_uri + ProjectHanlon.config.websvc_root

describe 'Hanlon::WebService::Policy' do

  include ProjectHanlon::HttpHelper

  before(:all) do
    $model_uuid = nil
    $policy_uuid = nil

    # Create a temporary model to facilitate creating a policy below
    uri = URI.parse(hnl_uri + '/model')

    template = 'discover_only'
    label = 'spec_temp_model'

    body_hash = {
        :template => template,
        :label => label,
        :req_metadata_params => {},
    }
    json_data = body_hash.to_json

    # make the request
    hnl_response, http_response = hnl_http_post_json_data(uri, json_data, true)
    # parse the output and validate
    parsed = JSON.parse(http_response.body)
    unless parsed['http_err_code'] == 201
      raise 'Could not create a temporary model'
    end
    # save the created UUID for later use
    $model_uuid = hnl_response['@uuid']

  end

  after(:all) do
    # Delete the temporary model used for testing
    uri = URI.parse(hnl_uri + '/model/' + $model_uuid)
    # make the request
    hnl_response = hnl_http_delete(uri)
    # parse the output and validate
    unless hnl_response.include? $model_uuid
      raise 'Could not remove the temporary model'
    end
  end

  describe 'resource :policy' do

    describe 'GET /policy' do
      it 'Returns a list of all policy instances' do
        uri = URI.parse(hnl_uri + '/policy')
        # make the request
        hnl_response, http_response = hnl_http_get(uri, true)
        # parse the output and validate
        parsed = JSON.parse(http_response.body)
        expect(parsed['resource']).to eq('ProjectHanlon::Slice::Policy')
        expect(parsed['command']).to eq('get_all_policies')
        expect(parsed['result']).to eq('Ok')
        expect(parsed['http_err_code']).to eq(200)
        expect(parsed['errcode']).to eq(0)
        expect(hnl_response).to_not be(nil)
      end
    end   # end GET /policy

    describe 'POST /policy' do
      it 'Creates a new policy instance' do
        uri = URI.parse(hnl_uri + '/policy')

        template = 'discover_only'
        label = 'spec_test_policy'
        model_uuid = $model_uuid
        tags = 'cpus_2'

        body_hash = {
            :template => template,
            :label => label,
            :model_uuid => model_uuid,
            :tags => tags,
        }
        json_data = body_hash.to_json

        # make the request
        hnl_response, http_response = hnl_http_post_json_data(uri, json_data, true)
        # parse the output and validate
        parsed = JSON.parse(http_response.body)
        expect(parsed['resource']).to eq('ProjectHanlon::Slice::Policy')
        expect(parsed['command']).to eq('create_policy')
        expect(parsed['result']).to eq('Created')
        expect(parsed['http_err_code']).to eq(201)
        expect(parsed['errcode']).to eq(0)
        # save the created UUID for later use
        $policy_uuid = hnl_response['@uuid']
      end
    end   # end POST /policy

    describe 'resource :templates' do

      describe 'GET /policy/templates' do
        it 'Returns a list of available policy templates' do
          uri = URI.parse(hnl_uri + '/policy/templates')
          # make the request
          hnl_response, http_response = hnl_http_get(uri, true)
          # parse the output and validate
          parsed = JSON.parse(http_response.body)
          expect(parsed['resource']).to eq('ProjectHanlon::Slice::Policy')
          expect(parsed['command']).to eq('get_policy_templates')
          expect(parsed['result']).to eq('Ok')
          expect(parsed['http_err_code']).to eq(200)
          expect(parsed['errcode']).to eq(0)
          expect(hnl_response[0]['@noun']).to eq('policy')
        end
      end   # end GET /policy/templates

      describe 'resource /:name' do

        describe 'GET /policy/templates/{name}' do
          it 'Returns details for a specific policy template (by name)' do

            template = 'discover_only'

            uri = URI.parse(hnl_uri + '/policy/templates/' + template)

            # make the request
            hnl_response, http_response = hnl_http_get(uri, true)
            # parse the output and validate
            parsed = JSON.parse(http_response.body)
            expect(parsed['resource']).to eq('ProjectHanlon::Slice::Policy')
            expect(parsed['command']).to eq('get_policy_template_by_name')
            expect(parsed['result']).to eq('Ok')
            expect(parsed['http_err_code']).to eq(200)
            expect(parsed['errcode']).to eq(0)
            expect(hnl_response['@template']).to eq(template)
          end
        end   # end GET /policy/templates/{name}

      end   # end resource /:name

    end   # end resource :templates

    describe 'resource :callback' do
      # TODO - 'resource :callback' not yet implemented
    end   # resource :callback

    describe 'resource /:uuid' do

      describe 'GET /policy/{uuid}' do
        it 'Returns details for a specific policy instance (by uuid)' do
          uri = URI.parse(hnl_uri + '/policy/' + $policy_uuid)
          # make the request
          hnl_response, http_response = hnl_http_get(uri, true)
          # parse the output and validate
          parsed = JSON.parse(http_response.body)
          expect(parsed['resource']).to eq('ProjectHanlon::Slice::Policy')
          expect(parsed['command']).to eq('get_policy_by_uuid')
          expect(parsed['result']).to eq('Ok')
          expect(parsed['http_err_code']).to eq(200)
          expect(parsed['errcode']).to eq(0)
          # make sure we are getting the same policy
          expect(hnl_response['@uuid']).to eq($policy_uuid)
        end
      end   # end GET /policy/{uuid}

      describe 'PUT /policy/{uuid}' do
        it 'Updates a policy instance (by uuid)' do
          uri = URI.parse(hnl_uri + '/policy/' + $policy_uuid)

          label = 'new_spec_test_policy'

          body_hash = {
              :label => label,
          }
          json_data = body_hash.to_json

          # make the request
          hnl_response, http_response = hnl_http_put_json_data(uri, json_data, true)
          # parse the output and validate
          parsed = JSON.parse(http_response.body)
          expect(parsed['resource']).to eq('ProjectHanlon::Slice::Policy')
          expect(parsed['command']).to eq('update_policy')
          expect(parsed['result']).to eq('Updated')
          expect(parsed['http_err_code']).to eq(202)
          expect(parsed['errcode']).to eq(0)
          # make sure we are updating the label
          expect(hnl_response['@label']).to eq(label)
        end
      end   # end PUT /policy/{uuid}

      describe 'DELETE /policy/{uuid}' do
        it 'Removes a policy instance (by uuid)' do
          uri = URI.parse(hnl_uri + '/policy/' + $policy_uuid)
          # make the request
          hnl_response, http_response = hnl_http_delete(uri, true)
          # parse the output and validate
          parsed = JSON.parse(http_response.body)
          expect(parsed['resource']).to eq('ProjectHanlon::Slice::Policy')
          expect(parsed['command']).to eq('remove_policy_by_uuid')
          expect(parsed['result']).to eq('Removed')
          expect(parsed['http_err_code']).to eq(202)
          expect(parsed['errcode']).to eq(0)
          # make sure we are returning the same policy uuid
          expect(hnl_response).to include($policy_uuid)
        end
      end   # end DELETE /policy/{uuid}

    end   # end resource /:uuid

  end   # end resource :policy

end
