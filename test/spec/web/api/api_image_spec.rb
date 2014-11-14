require 'open-uri'
hnl_uri = ProjectHanlon.config.hanlon_uri + ProjectHanlon.config.websvc_root

describe 'Hanlon::WebService::Image' do

  include SpecHttpHelper

  before(:all) do
    $lcl_hnl_path = nil
    $image_uuid = nil

    # Check for the hanlon mk ISO and download if missing
    # Disabling this section until proper image testing can be performed
    # hnl_mk_iso = 'hnl_mk_prod-image.2.0.0.iso'
    # $lcl_hnl_path = $hanlon_root + '/test/res/' + hnl_mk_iso
    # unless File.exist?($lcl_hnl_path)
    #   puts 'No hanlon ISO file, downloading...'
    #   hnl_source = 'https://github.com/csc/Hanlon-Microkernel/releases/download/v2.0.0/hnl_mk_prod-image.2.0.0.iso'
    #   uri = URI.parse(hnl_source)
    #   File.open($lcl_hnl_path, 'wb') do |saved_file|
    #     # Using open-uri here to follow redirects (AWS) and to handle large files
    #     open(uri, 'rb') do |read_file|
    #       saved_file.write(read_file.read)
    #     end
    #   end
    # end
  end

  describe 'resource :image' do

    describe 'GET /image' do
      it 'Returns a list of all image instances' do
        uri = URI.parse(hnl_uri + '/image')
        # make the request
        response = spec_http_get(uri)
        # parse the output and validate
        parsed = JSON.parse(response.body)
        expect(parsed['resource']).to eq('ProjectHanlon::Slice::Image')
        expect(parsed['command']).to eq('get_all_images')
        expect(parsed['result']).to eq('Ok')
        expect(parsed['http_err_code']).to eq(200)
        expect(parsed['errcode']).to eq(0)
      end
    end   # end GET /image

    # Disabling this section until proper image testing can be performed

    # describe 'POST /image' do
    #   it 'Creates a new image instance (from an ISO file)' do
    #     uri = URI.parse(hnl_uri + '/image')
    #
    #     type = 'mk'
    #     path = $lcl_hnl_path
    #
    #     body_hash = {
    #         :type => type,
    #         :path => path,
    #     }
    #     json_data = body_hash.to_json
    #
    #     # make the request
    #     response = spec_http_post_json_data(uri, json_data)
    #     # parse the output and validate
    #     parsed = JSON.parse(response.body)
    #     expect(parsed['resource']).to eq('ProjectHanlon::Slice::Image')
    #     expect(parsed['command']).to eq('create_image')
    #     expect(parsed['result']).to eq('Created')
    #     expect(parsed['http_err_code']).to eq(201)
    #     expect(parsed['errcode']).to eq(0)
    #     # save the created UUID for later use
    #     $image_uuid = parsed['response']['@uuid']
    #   end
    # end   # end POST /image
    #
    # describe 'resource /:component' do
    #
    #   describe 'GET /image/{component}' do
    #
    #     it 'Returns details for an image (by UUID)' do
    #       uri = URI.parse(hnl_uri + '/image/' + $image_uuid)
    #       # make the request
    #       response = spec_http_get(uri)
    #       # parse the output and validate
    #       parsed = JSON.parse(response.body)
    #       expect(parsed['resource']).to eq('ProjectHanlon::Slice::Image')
    #       expect(parsed['command']).to eq('get_image_by_uuid')
    #       expect(parsed['result']).to eq('Ok')
    #       expect(parsed['http_err_code']).to eq(200)
    #       expect(parsed['errcode']).to eq(0)
    #       # make sure we are getting the same image
    #       expect(parsed['response']['@uuid']).to eq($image_uuid)
    #     end
    #
    #     it 'Returns a file from an image (by path)' do
    #       uri = URI.parse(hnl_uri + '/image/mk/' + $image_uuid + '/LICENSE')
    #       # make the request
    #       response = spec_http_get(uri)
    #       # parse the output and validate
    #       # we expect the image LICENSE file to start with Hanlon MicroKernel
    #       expect(response.body.start_with?('Hanlon MicroKernel')).to eq(true)
    #     end
    #
    #   end   # end GET /image/{component}
    #
    #   describe 'DELETE /image/{component}' do
    #     it 'Removes an image (by UUID) and it\'s components' do
    #       uri = URI.parse(hnl_uri + '/image/' + $image_uuid)
    #       # make the request
    #       response = spec_http_delete(uri)
    #       # parse the output and validate
    #       parsed = JSON.parse(response.body)
    #       expect(parsed['resource']).to eq('ProjectHanlon::Slice::Image')
    #       expect(parsed['command']).to eq('remove_image_by_uuid')
    #       expect(parsed['result']).to eq('Removed')
    #       expect(parsed['http_err_code']).to eq(202)
    #       expect(parsed['errcode']).to eq(0)
    #       # make sure we are returning the same image uuid
    #       expect(parsed['response']).to include($image_uuid)
    #     end
    #   end   # end DELETE /image/{component}
    #
    # end   # end resource /:component

  end   # end resource :image

end
