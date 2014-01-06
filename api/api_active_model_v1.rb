#

require 'json'
require 'api_utils'

module Razor
  module WebService
    module ActiveModel

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

          def request_is_from_razor_server(ip_addr)
            Razor::WebService::Utils::request_from_razor_server?(ip_addr)
          end

          def get_active_model_by_uuid(uuid)
            slice_ref = ProjectRazor::Slice.new
            active_model = slice_ref.get_object("active_model_instance", :active, uuid)
            raise ProjectRazor::Error::Slice::InvalidUUID, "Cannot Find Active Model with UUID: [#{uuid}]" unless active_model && (active_model.class != Array || active_model.length > 0)
            active_model
          end

          def get_logs_for_active_model(active_model, with_uuid = false)
            # Take each element in our attributes_hash and store as a HashPrint object in our array
            last_time = nil
            first_time = nil
            log_entries = []
            index = 0
            active_model.model.log.each { |log_entry|
              entry_time = Time.at(log_entry["timestamp"])
              entry_time_int = entry_time.to_i
              first_time ||= entry_time
              last_time ||= entry_time
              total_time_diff = entry_time - first_time
              last_time_diff = entry_time - last_time
              hash_entry = { :State => active_model.state_print(log_entry["old_state"].to_s,log_entry["state"].to_s),
                             :Action => log_entry["action"].to_s,
                             :Result => log_entry["result"].to_s,
                             :Time => entry_time.strftime('%Y-%m-%d %H:%M:%S %Z'),
                             :Last => active_model.pretty_time(last_time_diff.to_i),
                             :Total => active_model.pretty_time(total_time_diff.to_i)
              }
              hash_entry[:NodeUUID] = active_model.node_uuid if with_uuid
              log_entries << hash_entry
              last_time = Time.at(log_entry["timestamp"])
              index = index + 1
            }
            log_entries
          end

        end

        resource :active_model do

          # GET /active_model
          # Retrieve list of active_models.
          get do
            slice_ref = ProjectRazor::Slice.new
            Razor::WebService::Response.new(200, 'OK', 'Success.', slice_ref.get_object("active_models", :active))
          end     # end GET /active_model

          resource '/logs' do

            # GET /active_model
            # Retrieve list of active_models.
            before do
              # only allow access to this resource from the Razor subnet
              unless request_is_from_razor_server(env['REMOTE_ADDR'])
                error!({ error: "Remote Access Forbidden",
                         detail: "Access to /active_model/logs resource is only allowed from Razor server",
                       }, 403)
              end
            end
            get do
              slice_ref = ProjectRazor::Slice.new
              active_models = slice_ref.get_object("active_models", :active)
              log_items = []
              active_models.each { |bp| log_items = log_items | get_logs_for_active_model(bp, true) }
              log_items.sort! { |a, b| a[:Time] <=> b[:Time] }
              Razor::WebService::Response.new(200, 'OK', 'Success.', log_items)
            end     # end GET /active_model/logs

          end     # end resource /active_model/logs

          resource '/:uuid' do

            # GET /active_model/{uuid}
            # Retrieve a specific active_model (by UUID).
            params do
              requires :uuid, type: String
            end
            get do
              uuid = params[:uuid]
              Razor::WebService::Response.new(200, 'OK', 'Success.', get_active_model_by_uuid(uuid))
            end     # end GET /active_model/{uuid}

            resource '/logs' do

              # GET /active_model/{uuid}/logs
              # Retrieve the log for an active_model (by UUID).
              before do
                # only allow access to this resource from the Razor subnet
                unless request_is_from_razor_server(env['REMOTE_ADDR'])
                  error!({ error: "Remote Access Forbidden",
                           detail: "Access to /active_model/{uuid}/logs resource is only allowed from Razor server",
                         }, 403)
                end
              end
              params do
                requires :uuid, type: String
              end
              get do
                uuid = params[:uuid]
                active_model = get_active_model_by_uuid(uuid)
                Razor::WebService::Response.new(200, 'OK', 'Success.', get_logs_for_active_model(active_model))
              end     # end GET /active_model/{uuid}/logs

            end       # end resource /active_model/:uuid/logs

          end       # end resource /active_model/:uuid

        end         # end resource /active_model

      end

    end

  end

end
