#

require 'json'
require 'api_utils'

module Razor
  module WebService
    module Tag

      class APIv1 < Grape::API

        version :v1, :using => :path, :vendor => "razor"
        format :json
        default_format :json

        rescue_from ProjectRazor::Error::Slice::InvalidUUID do |e|
          Rack::Response.new(
              Razor::WebService::Response.new(400, e.class.name, e.message).to_json,
              400,
              { "Content-type" => "application/json" }
          )
        end

        rescue_from Grape::Exceptions::Validation do |e|
          Rack::Response.new(
              Razor::WebService::Response.new(400, e.class.name, e.message).to_json,
              400,
              { "Content-type" => "application/json" }
          )
        end

        rescue_from :all do |e|
          raise e
          Rack::Response.new(
              Razor::WebService::Response.new(500, e.class.name, e.message).to_json,
              500,
              { "Content-type" => "application/json" }
          )
        end

        helpers do

          def content_type_header
            settings[:content_types][env['api.format']]
          end

          def api_format
            env['api.format']
          end

          def is_uuid?(string_)
            string_ =~ /[a-fA-F0-9]{8}-[a-fA-F0-9]{4}-[a-fA-F0-9]{4}-[a-fA-F0-9]{4}-[a-fA-F0-9]{12}/
          end

          def get_data_ref
            Razor::WebService::Utils::get_data
          end

          def slice_success_web(slice, command, response, options = {})
            Razor::WebService::Utils::rz_slice_success_web(slice, command, response, options)
          end

          def response_with_status_web(slice, command, response, options = {})
            Razor::WebService::Utils::rz_response_with_status(slice, command, response, options)
          end

          def find_matcher_for_tag(tag_uuid, matcher_uuid)
            found_matcher = []
            slice_ref = ProjectRazor::Slice.new
            tag = slice_ref.get_object("tag_with_uuid", :tag, tag_uuid)
            tag.tag_matchers.each { |matcher|
              found_matcher << [matcher, tag] if matcher.uuid.scan(matcher_uuid).count > 0
            }
            found_matcher.count == 1 ? found_matcher.first : nil
          end

          def get_matchers(tag_uuid)
            matchers = []
            slice_ref = ProjectRazor::Slice.new
            tag = slice_ref.get_object("tag_with_uuid", :tag, tag_uuid)
            tag.tag_matchers.each { |matcher|
              matchers << matcher
            }
            [matchers, tag]
          end

        end

        resource :tag do

          # GET /tag
          # Query for defined tags.
          get do
            slice_ref = ProjectRazor::Slice.new
            Razor::WebService::Response.new(200, 'OK', 'Success.', slice_ref.get_object("tagrules", :tag))
          end     # end GET /tag

          # POST /tag
          # Create a Razor tag
          #   parameters:
          #     name            | String | The "name" to use for the new tag   |         | Default: unavailable
          #     tag             | String | The "tag" value                     |         | Default: unavailable
          params do
            requires "name", type: String
            requires "tag", type: String
          end
          post do
            tag_slice = ProjectRazor::Slice::Tag.new([])
            # create a new tag using the options that were passed into this subcommand,
            # then persist the tag
            tagrule = ProjectRazor::Tagging::TagRule.new({"@name" => params["name"], "@tag" => params["tag"]})
            raise(ProjectRazor::Error::Slice::CouldNotCreate, "Could not create Tag Rule") unless tagrule
            get_data_ref.persist_object(tagrule)
            response_with_status_web(tag_slice, :create_tag, [tagrule], :success_type => :created)
          end     # end POST /tag

          resource '/:uuid' do

            # GET /tag/{uuid}
            # Query for the state of a specific tag.
            params do
              requires :uuid, type: String
            end
            get do
              slice_ref = ProjectRazor::Slice.new
              tag_uuid = params[:uuid]
              tagrule = slice_ref.get_object("tagrule_by_uuid", :tag, tag_uuid)
              raise ProjectRazor::Error::Slice::NotFound, "Tag UUID: [#{tag_uuid}]" unless tagrule && (tagrule.class != Array || tagrule.length > 0)
              Razor::WebService::Response.new(200, 'OK', 'Success.', tagrule)
            end     # end GET /tag/{uuid}

            # PUT /tag/{uuid}
            # Update a Razor tag (either the name or tag, or boht, can be updated using
            # this endpoint)
            #   parameters:
            #     name            | String | The new "name" to assign to the tag      |         | Default: unavailable
            #     tag             | String | The new "tag" value to assign to the tag |         | Default: unavailable
            params do
              requires :uuid, type: String
              optional "name", type: String
              optional "tag", type: String
            end
            put do
              # get the input parameters that were passed in as part of the request
              # (at least one of these should be a non-nil value)
              tag_uuid = params[:uuid]
              name = params["name"]
              tag = params["tag"]
              # check the values that were passed in (and gather new meta-data if
              # the --change-metadata flag was included in the update command and the
              # command was invoked via the CLI...it's an error to use this flag via
              # the RESTful API, the req_metadata_hash should be used instead)
              tag_slice = ProjectRazor::Slice::Tag.new([])
              # get the tag to update
              tagrule = tag_slice.get_object("tagrule_with_uuid", :tag, tag_uuid)
              raise ProjectRazor::Error::Slice::InvalidUUID, "Cannot Find Tag Rule with UUID: [#{tag_uuid}]" unless tagrule && (tagrule.class != Array || tagrule.length > 0)
              tagrule.name = name if name
              tagrule.tag = tag if tag
              raise ProjectRazor::Error::Slice::CouldNotUpdate, "Could not update Tag Rule [#{tagrule.uuid}]" unless tagrule.update_self
              response_with_status_web(tag_slice, :update_tag, [tagrule], :success_type => :updated)
            end     # end PUT /tag/{uuid}

            # DELETE /tag/{uuid}
            # Remove a Razor tag (by UUID)
            params do
              requires :uuid, type: String
            end
            delete do
              tag_slice = ProjectRazor::Slice::Tag.new([])
              tag_uuid = params[:uuid]
              tagrule = tag_slice.get_object("tag_with_uuid", :tag, tag_uuid)
              raise ProjectRazor::Error::Slice::InvalidUUID, "Cannot Find Tag with UUID: [#{tag_uuid}]" unless tagrule && (tagrule.class != Array || tagrule.length > 0)
              raise ProjectRazor::Error::Slice::CouldNotRemove, "Could not remove Tag [#{tag.uuid}]" unless get_data_ref.delete_object(tagrule)
              slice_success_web(tag_slice, :remove_tag_by_uuid, "Tag [#{tagrule.uuid}] removed", :success_type => :removed)
            end     # end DELETE /tag/{uuid}

            resource :matcher do

              # GET /tag/{uuid}/matcher
              # Query for defined tag matchers (for a given tag).
              get do
                slice_ref = ProjectRazor::Slice.new
                tag_uuid = params[:uuid]
                matchers, tagrule = get_matchers(tag_uuid)
                raise ProjectRazor::Error::Slice::InvalidUUID, "Cannot Find Tag with UUID: [#{tag_uuid}]" unless tagrule && (tagrule.class != Array || tagrule.length > 0)
                Razor::WebService::Response.new(200, 'OK', 'Success.', matchers)
              end     # end GET /tag/{uuid}/matcher

              # POST /tag/{uuid}/matcher
              # Create a Razor tag matcher (and add to the given tag)
              #   parameters:
              #     key             | String | The "name" to use for the new tag   |         | Default: unavailable
              #     compare         | String | The "tag" value                     |         | Default: unavailable
              #     value           | String | The "tag" value                     |         | Default: unavailable
              #     inverse         | String | The "tag" value                     |         | Default: unavailable
              params do
                requires "key", type: String
                requires "compare", type: String
                requires "value", type: String
                optional "inverse", type: String
              end
              post do
                tag_slice = ProjectRazor::Slice::Tag.new([])
                tag_uuid = params[:uuid]
                key = params["key"]
                compare = params["compare"]
                value = params["value"]
                inverse = params["inverse"]
                # if an inverse value was not provided, default to false
                inverse = "false" unless inverse
                tagrule = tag_slice.get_object("tagrule_with_uuid", :tag, tag_uuid)
                raise ProjectRazor::Error::Slice::InvalidUUID, "Cannot Find Tag Rule with UUID: [#{tag_uuid}]" unless tagrule && (tagrule.class != Array || tagrule.length > 0)
                raise ProjectRazor::Error::Slice::MissingArgument, "Value for 'compare' must be [equal|like]" unless compare == "equal" || compare == "like"
                raise ProjectRazor::Error::Slice::MissingArgument, "Value for 'inverse' must be [true|false]" unless inverse == "true" || inverse == "false"
                matcher = tagrule.add_tag_matcher(:key => key, :compare => compare, :value => value, :inverse => inverse)
                raise ProjectRazor::Error::Slice::CouldNotCreate, "Could not create tag matcher" unless matcher
                raise(ProjectRazor::Error::Slice::CouldNotCreate, "Could not create Tag Matcher") unless tagrule.update_self
                response_with_status_web(tag_slice, :create_matcher, [matcher], :success_type => :created)
              end     # end POST /tag/{uuid}/matcher

              resource '/:matcher_uuid' do

                # GET /tag/{uuid}/matcher/{matcher_uuid}
                # Query for the state of a specific tag matcher (for a specific tag).
                params do
                  requires :uuid, type: String
                  requires :matcher_uuid, type: String
                end
                get do
                  tag_uuid = params[:uuid]
                  matcher_uuid = params[:matcher_uuid]
                  matcher, tagrule = find_matcher_for_tag(tag_uuid, matcher_uuid)
                  raise ProjectRazor::Error::Slice::InvalidUUID, "Cannot find Tag Matcher with UUID [#{matcher_uuid}] in Tag with UUID [#{tag_uuid}]" unless matcher
                  Razor::WebService::Response.new(200, 'OK', 'Success.', matcher)
                end     # end GET /tag/{uuid}/matcher/{matcher_uuid}

                # PUT /tag/{uuid}/matcher/{matcher_uuid}
                # Update a Razor tag matcher (values for any of the the key, compare, value, or inverse
                # fields can be updated using this endpoint)
                #   parameters:
                #     key             | String | The "name" to use for the new tag   |         | Default: unavailable
                #     compare         | String | The "tag" value                     |         | Default: unavailable
                #     value           | String | The "tag" value                     |         | Default: unavailable
                #     inverse         | String | The "tag" value                     |         | Default: unavailable
                params do
                  requires :uuid, type: String
                  requires :matcher_uuid, type: String
                  optional "key", type: String
                  optional "compare", type: String
                  optional "value", type: String
                  optional "inverse", type: String
                end
                put do
                  # get the input parameters that were passed in as part of the request
                  # (at least one of these should be a non-nil value)
                  tag_slice = ProjectRazor::Slice::Tag.new([])
                  tag_uuid = params[:uuid]
                  matcher_uuid = params[:matcher_uuid]
                  key = params["key"]
                  compare = params["compare"]
                  value = params["value"]
                  inverse = params["inverse"]
                  # find the matcher to update
                  matcher, tag = find_matcher_for_tag(tag_uuid, matcher_uuid)
                  # check the parameters received in the request
                  raise ProjectRazor::Error::Slice::InvalidUUID, "Cannot find Tag with UUID [#{tag_uuid}]" unless tag && (tag.class != Array || tag.length > 0)
                  raise ProjectRazor::Error::Slice::InvalidUUID, "Cannot find Tag Matcher with UUID [#{matcher_uuid}] in Tag with UUID [#{tag_uuid}]" unless matcher
                  raise ProjectRazor::Error::Slice::MissingArgument, "Value for 'compare' must be [equal|like]" unless !compare || compare == "equal" || compare == "like"
                  raise ProjectRazor::Error::Slice::MissingArgument, "Value for 'inverse' must be [true|false]" unless !inverse || inverse == "true" || inverse == "false"
                  # and update the fields in this matcher
                  matcher.key = key if key
                  matcher.compare = compare if compare
                  matcher.value = value if value
                  matcher.inverse = inverse if inverse
                  # throw an error if cannot update the tag with the new matcher
                  raise ProjectRazor::Error::Slice::CouldNotUpdate, "Could not update Tag Matcher [#{matcher.uuid}]" unless tag.update_self
                  response_with_status_web(tag_slice, :update_matcher, [matcher], :success_type => :updated)
                end     # end PUT /tag/{uuid}/matcher/{matcher_uuid}

                # DELETE /tag/{uuid}/matcher/{matcher_uuid}
                # Remove a Razor tag matcher (by UUID) from the specified Razor tag instance
                params do
                  requires :uuid, type: String
                end
                delete do
                  tag_slice = ProjectRazor::Slice::Tag.new([])
                  tag_uuid = params[:uuid]
                  matcher_uuid = params[:matcher_uuid]
                  matcher, tagrule = find_matcher_for_tag(tag_uuid, matcher_uuid)
                  raise ProjectRazor::Error::Slice::InvalidUUID, "Cannot find Tag with UUID [#{tag_uuid}]" unless tagrule && (tagrule.class != Array || tagrule.length > 0)
                  raise ProjectRazor::Error::Slice::InvalidUUID, "Cannot find Tag Matcher with UUID [#{matcher_uuid}] in Tag with UUID [#{tag_uuid}]" unless matcher && (matcher.class != Array || matcher.length > 0)
                  raise ProjectRazor::Error::Slice::CouldNotRemove, "Could not remove Tag Matcher [#{matcher.uuid}]" unless tagrule.remove_tag_matcher(matcher.uuid)
                  raise(ProjectRazor::Error::Slice::CouldNotCreate, "Could not remove Tag Matcher from Tag [#{tagrule.uuid}]") unless tagrule.update_self
                  slice_success_web(tag_slice, :remove_matcher, "Tag Matcher [#{matcher.uuid}] removed", :success_type => :removed)
                end     # end DELETE /tag/{uuid}/matcher/{matcher_uuid}

              end     # end resource /tag/:uuid/matcher/:matcher_uuid

            end     # end resource /tag/:uuid/matcher

          end     # end resource /tag/:uuid

        end     # end resource /tag

      end

    end

  end

end
