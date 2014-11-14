
hnl_uri = ProjectHanlon.config.hanlon_uri + ProjectHanlon.config.websvc_root

describe 'Hanlon::WebService::ActiveModel' do

  include ProjectHanlon::HttpHelper

  before(:all) do

    $hw_id = "TEST#{rand(9)}#{rand(9)}#{rand(9)}#{rand(9)}#{rand(9)}#{rand(9)}#{rand(9)}"
    $node_uuid = nil
    $model_uuid = nil
    $tag_uuid = nil
    $tag_matcher_uuid = nil
    $policy_uuid = nil
    $active_model_uuid = nil

    # Register a node with relevant attributes
    uri = URI.parse(hnl_uri + '/node/register')
    uuid = $hw_id
    last_state = 'idle'
    attributes_hash = {
        :hostname => 'hanlon.example.com',
        :ip_address => '1.1.1.1',
        :hardwaremodel => 'foobar',
    }
    body_hash = {
        :uuid => uuid,
        :last_state => last_state,
        :attributes_hash => attributes_hash,
    }
    json_data = body_hash.to_json
    # make the request
    hnl_response, http_response = hnl_http_post_json_data(uri, json_data, true)
    # parse the output and validate
    parsed = JSON.parse(http_response.body)
    unless parsed['http_err_code'] == 200
      raise 'Could not register a temporary node'
    end
    # save the created UUID for later use
    $node_uuid = hnl_response['@uuid']


    # Create a discover_only model
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


    # Create a tag
    uri = URI.parse(hnl_uri + '/tag')
    name = 'spec_temp_tag'
    tag = 'spec_temp_tag'
    body_hash = {
        :name => name,
        :tag => tag,
    }
    json_data = body_hash.to_json
    # make the request
    hnl_response, http_response = hnl_http_post_json_data(uri, json_data, true)
    # parse the output and validate
    parsed = JSON.parse(http_response.body)
    unless parsed['http_err_code'] == 201
      raise 'Could not create a temporary tag'
    end
    # save the created UUID for later use
    $tag_uuid = hnl_response['@uuid']


    # Create a tag matcher
    uri = URI.parse(hnl_uri + '/tag/' + $tag_uuid + '/matcher')
    key = 'hardwaremodel'
    compare = 'equal'
    value = 'foobar'
    body_hash = {
        :key => key,
        :compare => compare,
        :value => value,
    }
    json_data = body_hash.to_json
    # make the request
    hnl_response, http_response = hnl_http_post_json_data(uri, json_data, true)
    # parse the output and validate
    parsed = JSON.parse(http_response.body)
    unless parsed['http_err_code'] == 201
      raise 'Could not create a temporary tag matcher'
    end
    # save the created UUID for later use
    $tag_matcher_uuid = hnl_response['@uuid']


    # Create a discover_only policy with tag for node above
    uri = URI.parse(hnl_uri + '/policy')
    template = 'discover_only'
    label = 'spec_temp_policy'
    model_uuid = $model_uuid
    tags = 'spec_temp_tag'
    enabled = 'true'
    body_hash = {
        :template => template,
        :label => label,
        :model_uuid => model_uuid,
        :tags => tags,
        :enabled => enabled,
    }
    json_data = body_hash.to_json
    # make the request
    hnl_response, http_response = hnl_http_post_json_data(uri, json_data, true)
    # parse the output and validate
    parsed = JSON.parse(http_response.body)
    unless parsed['http_err_code'] == 201
      raise 'Could not create a temporary policy'
    end
    # save the created UUID for later use
    $policy_uuid = hnl_response['@uuid']

    # Perform node checkin
    uri = URI.parse(hnl_uri + "/node/checkin?hw_id=#{$hw_id}&last_state=idle")
    # make the request
    hnl_response = hnl_http_get(uri)
    # parse the output and validate
    unless hnl_response['command_name'] == 'acknowledge'
      raise 'Could not checkin temporary node'
    end

  end


  after(:all) do

    # Remove the policy
    uri = URI.parse(hnl_uri + '/policy/' + $policy_uuid)
    # make the request
    hnl_response = hnl_http_delete(uri)
    # parse the output and validate
    unless hnl_response.include? $policy_uuid
      raise 'Could not remove the temporary policy'
    end


    # Remove the tag
    uri = URI.parse(hnl_uri + '/tag/' + $tag_uuid)
    # make the request
    hnl_response = hnl_http_delete(uri)
    # parse the output and validate
    unless hnl_response.include? $tag_uuid
      raise 'Could not remove the temporary tag'
    end


    # Remove the model
    uri = URI.parse(hnl_uri + '/model/' + $model_uuid)
    # make the request
    hnl_response = hnl_http_delete(uri)
    # parse the output and validate
    unless hnl_response.include? $model_uuid
      raise 'Could not remove the temporary model'
    end

  end


  describe 'resource :active_model' do

    describe 'GET /active_model' do

      it 'Returns a list of all active model instances' do
        uri = URI.parse(hnl_uri + '/active_model')
        # make the request
        hnl_response, http_response = hnl_http_get(uri, true)
        # parse the output and validate
        parsed = JSON.parse(http_response.body)
        expect(parsed['resource']).to eq('ProjectHanlon::Slice::ActiveModel')
        expect(parsed['command']).to eq('get_all_active_models')
        expect(parsed['result']).to eq('Ok')
        expect(parsed['http_err_code']).to eq(200)
        expect(parsed['errcode']).to eq(0)
        expect(hnl_response[0]['@noun']).to eq('active_model')
      end

      it 'Returns an active model instance (by node_uuid)' do
        uri = URI.parse(hnl_uri + '/active_model?node_uuid=' + $node_uuid)
        # make the request
        hnl_response, http_response = hnl_http_get(uri, true)
        # parse the output and validate
        parsed = JSON.parse(http_response.body)
        expect(parsed['resource']).to eq('ProjectHanlon::Slice::ActiveModel')
        expect(parsed['command']).to eq('get_all_active_models')
        expect(parsed['result']).to eq('Ok')
        expect(parsed['http_err_code']).to eq(200)
        expect(parsed['errcode']).to eq(0)

        # Save the active_model for later tests
        $active_model_uuid = hnl_response['@uuid']
      end

      it 'Returns an active model instance (by hw_id)' do
        uri = URI.parse(hnl_uri + '/active_model?hw_id=' + $hw_id)
        # make the request
        hnl_response, http_response = hnl_http_get(uri, true)
        # parse the output and validate
        parsed = JSON.parse(http_response.body)
        expect(parsed['resource']).to eq('ProjectHanlon::Slice::ActiveModel')
        expect(parsed['command']).to eq('get_all_active_models')
        expect(parsed['result']).to eq('Ok')
        expect(parsed['http_err_code']).to eq(200)
        expect(parsed['errcode']).to eq(0)
        #make sure we are getting the same active model
        expect(hnl_response['@uuid']).to eq($active_model_uuid)
      end

    end   # end GET /active_model

    describe 'DELETE /active_model' do
      # it 'Removes an active model instance (by node_uuid)' do
      #   # TODO - DELETE /active_model by (by node_uuid) not yet implemented
      #
      # end
      # it 'Removes an active model instance (by hw_id)' do
      #   # TODO - DELETE /active_model by (by hw_id) not yet implemented
      #
      # end
    end   # end DELETE /active_model

    describe 'resource /logs' do

      describe 'GET /active_model/logs' do
        it 'Returns the log entries for all active model instances' do
          uri = URI.parse(hnl_uri + '/active_model/logs')
          # make the request
          hnl_response, http_response = hnl_http_get(uri, true)
          # parse the output and validate
          parsed = JSON.parse(http_response.body)
          expect(parsed['resource']).to eq('ProjectHanlon::Slice::ActiveModel')
          expect(parsed['command']).to eq('get_active_model_logs')
          expect(parsed['result']).to eq('Ok')
          expect(parsed['http_err_code']).to eq(200)
          expect(parsed['errcode']).to eq(0)
          expect(hnl_response).to_not be(nil)
        end
      end   # end GET /active_model/logs

    end   # end resource /logs

    describe 'resource /:uuid' do

      describe 'GET /active_model/{uuid}' do
        it 'Returns the details for a specific active model instance (by uuid)' do
          uri = URI.parse(hnl_uri + '/active_model/' + $active_model_uuid)
          # make the request
          hnl_response, http_response = hnl_http_get(uri, true)
          # parse the output and validate
          parsed = JSON.parse(http_response.body)
          expect(parsed['resource']).to eq('ProjectHanlon::Slice::ActiveModel')
          expect(parsed['command']).to eq('get_active_model_by_uuid')
          expect(parsed['result']).to eq('Ok')
          expect(parsed['http_err_code']).to eq(200)
          expect(parsed['errcode']).to eq(0)
          expect(hnl_response['@uuid']).to eq($active_model_uuid)
        end
      end   # end GET /active_model/{uuid}

      describe 'resource /logs' do
        describe 'GET /active_model/{uuid}/logs' do
          it 'Returns the log entries for a specific active model instance (by uuid)' do
            uri = URI.parse(hnl_uri + '/active_model/' + $active_model_uuid + '/logs')
            # make the request
            hnl_response, http_response = hnl_http_get(uri, true)
            # parse the output and validate
            parsed = JSON.parse(http_response.body)
            expect(parsed['resource']).to eq('ProjectHanlon::Slice::ActiveModel')
            expect(parsed['command']).to eq('get_active_model_logs')
            expect(parsed['result']).to eq('Ok')
            expect(parsed['http_err_code']).to eq(200)
            expect(parsed['errcode']).to eq(0)
            expect(hnl_response).to_not be(nil)
          end
        end   # end GET /active_model/{uuid}/logs
      end   # end resource /logs

      describe 'DELETE /active_model/{uuid}' do
        it 'Removes an active model instance (by uuid)' do
          uri = URI.parse(hnl_uri + '/active_model/' + $active_model_uuid)
          # make the request
          hnl_response, http_response = hnl_http_delete(uri, true)
          # parse the output and validate
          parsed = JSON.parse(http_response.body)
          expect(parsed['resource']).to eq('ProjectHanlon::Slice::ActiveModel')
          expect(parsed['command']).to eq('remove_active_model_by_uuid')
          expect(parsed['result']).to eq('Removed')
          expect(parsed['http_err_code']).to eq(202)
          expect(parsed['errcode']).to eq(0)
          # make sure we are returning the same active_model uuid
          expect(hnl_response).to include($active_model_uuid)
        end
      end   # end DELETE /active_model/{uuid}

    end   # end resource /:uuid

  end   # end resource :active_model

end
