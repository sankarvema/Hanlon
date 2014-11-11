
hnl_uri = ProjectHanlon.config.hanlon_uri + ProjectHanlon.config.websvc_root

describe 'Hanlon::WebService::Tag' do

  describe 'resource :tag' do

    describe 'GET /tag' do
      it 'Returns a list of all tags' do
        uri = URI.parse(hnl_uri + '/tag')
        http_client = Net::HTTP.new(uri.host, uri.port)
        request = Net::HTTP::Get.new(uri.request_uri)
        # make the request
        response = http_client.request(request)
        # parse the output and validate
        parsed = JSON.parse(response.body)
        expect(parsed['resource']).to eq('ProjectHanlon::Slice::Tag')
        expect(parsed['command']).to eq('get_all_tagrules')
        expect(parsed['result']).to eq('Ok')
        expect(parsed['http_err_code']).to eq(200)
        expect(parsed['errcode']).to eq(0)
      end
    end   # end GET /tag

    describe 'POST /tag' do
      it 'Creates a new tag' do
        uri = URI.parse(hnl_uri + '/tag')

        name = 'spec_tag'
        tag = 'my_spec_tag'

        body_hash = {
            :name => name,
            :tag => tag,
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
        expect(parsed['resource']).to eq('ProjectHanlon::Slice::Tag')
        expect(parsed['command']).to eq('create_tag')
        expect(parsed['result']).to eq('Created')
        expect(parsed['http_err_code']).to eq(201)
        expect(parsed['errcode']).to eq(0)
        # save the created UUID for later use
        $tag_uuid = parsed['response']['@uuid']
      end
    end   # end POST /tag

    describe 'resource /:uuid' do

      describe 'GET /tag/{uuid}' do
        it 'Returns details for a specific tag (by uuid)' do
          uri = URI.parse(hnl_uri + '/tag/' + $tag_uuid)
          http_client = Net::HTTP.new(uri.host, uri.port)
          request = Net::HTTP::Get.new(uri.request_uri)
          # make the request
          response = http_client.request(request)
          # parse the output and validate
          parsed = JSON.parse(response.body)
          expect(parsed['resource']).to eq('ProjectHanlon::Slice::Tag')
          expect(parsed['command']).to eq('get_tagrule_by_uuid')
          expect(parsed['result']).to eq('Ok')
          expect(parsed['http_err_code']).to eq(200)
          expect(parsed['errcode']).to eq(0)
          # make sure we are getting the same tag
          expect(parsed['response']['@uuid']).to eq($tag_uuid)
        end
      end   # end GET /tag/{uuid}

      describe 'PUT /tag/{uuid}' do
        it 'Updates a specific tag (by uuid)' do
          uri = URI.parse(hnl_uri + '/tag/' + $tag_uuid)

          name = 'new_spec_tag'

          body_hash = {
              :name => name,
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
          expect(parsed['resource']).to eq('ProjectHanlon::Slice::Tag')
          expect(parsed['command']).to eq('update_tag')
          expect(parsed['result']).to eq('Updated')
          expect(parsed['http_err_code']).to eq(202)
          expect(parsed['errcode']).to eq(0)
          # make sure we are updating the label
          expect(parsed['response']['@name']).to eq(name)
        end
      end   # end PUT /tag/{uuid}

      # NOTE: the 'DELETE /tag/{uuid}' section was moved to the end because
      # we needed the tag to exist for further testing

      describe 'resource :matcher' do

        describe 'GET /tag/{uuid}/matcher' do
          it 'Returns a list of all tag matchers for a given tag (by uuid)' do
            uri = URI.parse(hnl_uri + '/tag/' + $tag_uuid + '/matcher')
            http_client = Net::HTTP.new(uri.host, uri.port)
            request = Net::HTTP::Get.new(uri.request_uri)
            # make the request
            response = http_client.request(request)
            # parse the output and validate
            parsed = JSON.parse(response.body)
            expect(parsed['resource']).to eq('ProjectHanlon::Slice::Tag')
            expect(parsed['command']).to eq('get_all_matchers')
            expect(parsed['result']).to eq('Ok')
            expect(parsed['http_err_code']).to eq(200)
            expect(parsed['errcode']).to eq(0)
          end
        end   # end GET /tag/{uuid}/matcher

        describe 'POST /tag/{uuid}/matcher' do
          it 'Creates a new tag matcher (and adds to the specified tag)' do
            uri = URI.parse(hnl_uri + '/tag/' + $tag_uuid + '/matcher')

            key = 'hardwaremodel'
            compare = 'equal'
            value = 'i686'

            body_hash = {
                :key => key,
                :compare => compare,
                :value => value,
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
            expect(parsed['resource']).to eq('ProjectHanlon::Slice::Tag')
            expect(parsed['command']).to eq('create_matcher')
            expect(parsed['result']).to eq('Created')
            expect(parsed['http_err_code']).to eq(201)
            expect(parsed['errcode']).to eq(0)
            # save the created UUID for later use
            $tag_matcher_uuid = parsed['response']['@uuid']
          end
        end   # end POST /tag/{uuid}/matcher

        describe 'resource /:matcher_uuid' do

          describe 'GET /tag/{uuid}/matcher/{matcher_uuid}' do
            it 'Returns the details for a tag matcher (for the specified tag)' do
              uri = URI.parse(hnl_uri + '/tag/' + $tag_uuid + '/matcher/' + $tag_matcher_uuid)
              http_client = Net::HTTP.new(uri.host, uri.port)
              request = Net::HTTP::Get.new(uri.request_uri)
              # make the request
              response = http_client.request(request)
              # parse the output and validate
              parsed = JSON.parse(response.body)
              expect(parsed['resource']).to eq('ProjectHanlon::Slice::Tag')
              expect(parsed['command']).to eq('get_matcher_by_uuid')
              expect(parsed['result']).to eq('Ok')
              expect(parsed['http_err_code']).to eq(200)
              expect(parsed['errcode']).to eq(0)
            end
          end   # end GET /tag/{uuid}/matcher/{matcher_uuid}

          describe 'PUT /tag/{uuid}/matcher/{matcher_uuid}' do
            it 'Updates the details for a tag matcher (for the specified tag)' do
              uri = URI.parse(hnl_uri + '/tag/' + $tag_uuid + '/matcher/' + $tag_matcher_uuid)

              value = 'new_i686'

              body_hash = {
                  :value => value,
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
              expect(parsed['resource']).to eq('ProjectHanlon::Slice::Tag')
              expect(parsed['command']).to eq('update_matcher')
              expect(parsed['result']).to eq('Updated')
              expect(parsed['http_err_code']).to eq(202)
              expect(parsed['errcode']).to eq(0)
              # make sure we are updating the label
              expect(parsed['response']['@value']).to eq(value)

            end
          end   # end PUT /tag/{uuid}/matcher/{matcher_uuid}

          describe 'DELETE /tag/{uuid}/matcher/{matcher_uuid}' do
            it 'Removes the details for a tag matcher (for the specified tag)' do
              uri = URI.parse(hnl_uri + '/tag/' + $tag_uuid + '/matcher/' + $tag_matcher_uuid)
              http_client = Net::HTTP.new(uri.host, uri.port)
              request = Net::HTTP::Delete.new(uri.request_uri)
              # make the request
              response = http_client.request(request)
              # parse the output and validate
              parsed = JSON.parse(response.body)
              expect(parsed['resource']).to eq('ProjectHanlon::Slice::Tag')
              expect(parsed['command']).to eq('remove_matcher')
              expect(parsed['result']).to eq('Removed')
              expect(parsed['http_err_code']).to eq(202)
              expect(parsed['errcode']).to eq(0)
              # make sure we are returning the same tag uuid
              expect(parsed['response']).to include($tag_matcher_uuid)
            end
          end   # end DELETE /tag/{uuid}/matcher/{matcher_uuid}

        end   # end resource /:matcher_uuid

      end   # end resource :matcher

      describe 'DELETE /tag/{uuid}' do
        it 'Removes a specific tag (by uuid)' do
          uri = URI.parse(hnl_uri + '/tag/' + $tag_uuid)
          http_client = Net::HTTP.new(uri.host, uri.port)
          request = Net::HTTP::Delete.new(uri.request_uri)
          # make the request
          response = http_client.request(request)
          # parse the output and validate
          parsed = JSON.parse(response.body)
          expect(parsed['resource']).to eq('ProjectHanlon::Slice::Tag')
          expect(parsed['command']).to eq('remove_tag_by_uuid')
          expect(parsed['result']).to eq('Removed')
          expect(parsed['http_err_code']).to eq(202)
          expect(parsed['errcode']).to eq(0)
          # make sure we are returning the same tag uuid
          expect(parsed['response']).to include($tag_uuid)
        end
      end   # end DELETE /tag/{uuid}

    end   # end resource /:uuid

  end   # end resource :tag

end
