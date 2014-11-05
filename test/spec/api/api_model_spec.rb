require 'yaml'
require 'json'

hnl_uri = ProjectHanlon.config.hanlon_uri + ProjectHanlon.config.websvc_root

describe 'Hanlon::WebService::Model' do

  describe 'resource :model' do

    uri_string = hnl_uri + '/model'

    describe 'GET /model' do

      context 'with no models' do

        it 'behaves one way' do
          # ...
          expect(:actual).to be(:expected)
        end

      end

      context 'with one or models' do
        it 'Returns a list of all model instances' do
          uri = URI.parse(uri_string)
          http_client = Net::HTTP.new(uri.host, uri.port)
          request = Net::HTTP::Get.new(uri.request_uri)
          response = http_client.request(request)
          expect(response.class).to eq(Net::HTTPOK)
        end

      end

    end

    describe 'POST /model' do

      it 'Creates a new model instance' do
        # ...
        expect(:actual).to be(:expected)
      end

    end

  end

  describe 'resource :templates' do

    uri_string = hnl_uri + '/model/templates'

    describe 'GET /model/templates' do
      it 'behaves this way' do
        # ...
        expect(:actual).to be(:expected)
      end

    end

  end

  describe 'resource /:name' do

    describe 'GET /model/templates/{name}' do
      it 'Returns details for a specific model template (by name)' do
        # ...
        expect(:actual).to be(:expected)
      end

    end

  end

  describe 'resource /:uuid' do

    describe 'GET /model/{uuid}' do
      it 'Returns details for a specific model instance (by UUID)' do
        # ...
        expect(:actual).to be(:expected)
      end
    end
  end

end
