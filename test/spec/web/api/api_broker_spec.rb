
hnl_uri = ProjectHanlon.config.hanlon_uri + ProjectHanlon.config.websvc_root

describe 'Hanlon::WebService::Broker' do

  include ProjectHanlon::HttpHelper

  before(:all) do
    $broker_uuid = nil
  end

  describe 'resource :broker' do

    describe 'GET /broker' do
      it 'Returns a list of all broker instances' do
        uri = URI.parse(hnl_uri + '/broker')
        # make the request
        hnl_response, http_response = hnl_http_get(uri, true)
        # parse the output and validate
        parsed = JSON.parse(http_response.body)
        expect(parsed['resource']).to eq('ProjectHanlon::Slice::Broker')
        expect(parsed['command']).to eq('get_all_brokers')
        expect(parsed['result']).to eq('Ok')
        expect(parsed['http_err_code']).to eq(200)
        expect(parsed['errcode']).to eq(0)
        expect(hnl_response).to_not be(nil)
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

        # make the request
        hnl_response, http_response = hnl_http_post_json_data(uri, json_data, true)
        # parse the output and validate
        parsed = JSON.parse(http_response.body)
        expect(parsed['resource']).to eq('ProjectHanlon::Slice::Broker')
        expect(parsed['command']).to eq('create_broker')
        expect(parsed['result']).to eq('Created')
        expect(parsed['http_err_code']).to eq(201)
        expect(parsed['errcode']).to eq(0)
        # save the created UUID for later use
        $broker_uuid = hnl_response['@uuid']
      end
    end   # end POST /broker

    describe 'resource :plugins' do

      describe 'GET /broker/plugins' do
        it 'Returns a list of available broker plugins' do
          uri = URI.parse(hnl_uri + '/broker/plugins')
          # make the request
          hnl_response, http_response = hnl_http_get(uri, true)
          # parse the output and validate
          parsed = JSON.parse(http_response.body)
          expect(parsed['resource']).to eq('ProjectHanlon::Slice::Broker')
          expect(parsed['command']).to eq('get_broker_plugins')
          expect(parsed['result']).to eq('Ok')
          expect(parsed['http_err_code']).to eq(200)
          expect(parsed['errcode']).to eq(0)
          expect(hnl_response[0]['@noun']).to eq('broker')
        end
      end   # end GET /broker/plugins

      describe 'resource /:name' do
        describe 'GET /broker/plugins/{name}' do
          it 'Returns details for a specific broker plugin (by name)' do

            broker = 'puppet'

            uri = URI.parse(hnl_uri + '/broker/plugins/' + broker)

            # make the request
            hnl_response, http_response = hnl_http_get(uri, true)
            # parse the output and validate
            parsed = JSON.parse(http_response.body)
            expect(parsed['resource']).to eq('ProjectHanlon::Slice::Broker')
            expect(parsed['command']).to eq('get_broker_plugin_by_uuid')
            expect(parsed['result']).to eq('Ok')
            expect(parsed['http_err_code']).to eq(200)
            expect(parsed['errcode']).to eq(0)
            expect(hnl_response['@plugin']).to eq(broker)
          end
        end   # end GET /broker/plugins/{name}
      end   # end resource /:name
    end   # end resource :plugins

    describe 'resource /:uuid' do

      describe 'GET /broker/{uuid}' do
        it 'Returns details for a specific broker instance (by UUID)' do
          uri = URI.parse(hnl_uri + '/broker/' + $broker_uuid)
          # make the request
          hnl_response, http_response = hnl_http_get(uri, true)
          # parse the output and validate
          parsed = JSON.parse(http_response.body)
          expect(parsed['resource']).to eq('ProjectHanlon::Slice::Broker')
          expect(parsed['command']).to eq('get_broker_by_uuid')
          expect(parsed['result']).to eq('Ok')
          expect(parsed['http_err_code']).to eq(200)
          expect(parsed['errcode']).to eq(0)
          # make sure we are getting the same broker
          expect(hnl_response['@uuid']).to eq($broker_uuid)
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

          # make the request
          hnl_response, http_response = hnl_http_put_json_data(uri, json_data, true)
          # parse the output and validate
          parsed = JSON.parse(http_response.body)
          expect(parsed['resource']).to eq('ProjectHanlon::Slice::Broker')
          expect(parsed['command']).to eq('update_broker')
          expect(parsed['result']).to eq('Updated')
          expect(parsed['http_err_code']).to eq(202)
          expect(parsed['errcode']).to eq(0)
          # make sure we are updating the name
          expect(hnl_response['@name']).to eq(name)
        end
      end   # end PUT /broker/{uuid}

      describe 'DELETE /broker/{uuid' do
        it 'Removes a broker instance (by UUID)' do
          uri = URI.parse(hnl_uri + '/broker/' + $broker_uuid)
          # make the request
          hnl_response, http_response = hnl_http_delete(uri, true)
          # parse the output and validate
          parsed = JSON.parse(http_response.body)
          expect(parsed['resource']).to eq('ProjectHanlon::Slice::Broker')
          expect(parsed['command']).to eq('remove_broker_by_uuid')
          expect(parsed['result']).to eq('Removed')
          expect(parsed['http_err_code']).to eq(202)
          expect(parsed['errcode']).to eq(0)
          # make sure we are returning the same broker uuid
          expect(hnl_response).to include($broker_uuid)
        end
      end   # end DELETE /broker/{uuid}

    end   # end resource /:uuid

  end   # end resource :broker


end

