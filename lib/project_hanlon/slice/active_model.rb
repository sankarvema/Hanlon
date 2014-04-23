require "json"
require "project_hanlon/policy/base"


# Root ProjectHanlon namespace
module ProjectHanlon
  class Slice

    # ProjectHanlon Slice Active_Model
    class ActiveModel < ProjectHanlon::Slice

      def initialize(args)
        super(args)
        @hidden     = false
        @policies   = ProjectHanlon::Policies.instance
        @uri_string = ProjectHanlon.config.mk_uri + HANLON_URI_ROOT + '/active_model'
      end

      def slice_commands
        # get the slice commands map for this slice (based on the set of
        # commands that are typical for most slices)
        commands = get_command_map(
          "active_model_help",
          "get_all_active_models",
          "get_active_model_by_uuid",
          nil,
          nil,
          "remove_all_active_models",
          "remove_active_model_by_uuid")

        commands[:logs] = "get_logs"
        commands[:get][/^(?!^(all|\-\-help|\-h|\{\}|\{.*\}|nil)$)\S+$/][:logs] = "get_active_model_logs"

        commands
      end

      def active_model_help
        if @prev_args.length > 1
          command = @prev_args.peek(1)
          begin
            # load the option items for this command (if they exist) and print them
            option_items = command_option_data(command)
            print_command_help(command, option_items)
            return
          rescue
          end
        end
        # if here, then either there are no specific options for the current command or we've
        # been asked for generic help, so provide generic help
        puts "Active Model Slice: used to view active models or active model logs, and to remove active models.".red
        puts "Active Model Commands:".yellow
        puts "\thanlon active_model [get] [all]          " + "View all active models".yellow
        puts "\thanlon active_model [get] (UUID) [logs]  " + "View specific active model (log)".yellow
        puts "\thanlon active_model logs                 " + "Prints an aggregate view of active model logs".yellow
        puts "\thanlon active_model remove (UUID)|all    " + "Remove existing (or all) active model(s)".yellow
        puts "\thanlon active_model --help|-h            " + "Display this screen".yellow
      end

      def get_all_active_models
        @command = :get_all_active_models
        raise ProjectHanlon::Error::Slice::SliceCommandParsingFailed,
              "Unexpected arguments found in command #{@command} -> #{@command_array.inspect}" if @command_array.length > 0
        uri = URI.parse @uri_string
        active_model_array = hash_array_to_obj_array(expand_response_with_uris(rz_http_get(uri)))
        print_object_array(active_model_array, "Active Models:", :style => :table)
      end

      def get_active_model_by_uuid
        @command = :get_active_model_by_uuid
        # the UUID is the first element of the @command_array
        uuid = get_uuid_from_prev_args
        # setup the proper URI depending on the options passed in
        uri = URI.parse(@uri_string + '/' + uuid)
        # and get the results of the appropriate RESTful request using that URI
        include_http_response = true
        result, response = rz_http_get(uri, include_http_response)
        if response.instance_of?(Net::HTTPBadRequest)
          raise ProjectHanlon::Error::Slice::CommandFailed, result["result"]["description"]
        end
        # finally, based on the options selected, print the results
        return print_object_array(hash_array_to_obj_array([result]), "Active Model:")
      end

      def get_active_model_logs
        @command = :get_active_model_logs
        # the UUID is the first element of the @command_array
        uuid = @prev_args.peek(1)
        # setup a URI to retrieve the active_model in question
        uri = URI.parse(@uri_string + '/' + uuid)
        # and get the results of the appropriate RESTful request using that URI
        include_http_response = true
        result, response = rz_http_get(uri, include_http_response)
        if response.instance_of?(Net::HTTPBadRequest)
          raise ProjectHanlon::Error::Slice::CommandFailed, result["result"]["description"]
        end
        # convert the result into an active_model instance, then use that instance to
        # print out the logs for that instance
        active_model_ref = hash_to_obj(result)
        print_object_array(active_model_ref.print_log, "", :style => :table)
      end

      def remove_all_active_models
        @command = :remove_all_active_models
        raise ProjectHanlon::Error::Slice::MethodNotAllowed, "This method has been deprecated"
      end

      def remove_active_model_by_uuid
        @command = :remove_active_model_by_uuid
        # the UUID is the first element of the @command_array
        uuid = get_uuid_from_prev_args
        # setup the DELETE (to update the remove the indicated active_model) and return the results
        uri = URI.parse @uri_string + "/#{uuid}"
        result, response = rz_http_delete(uri, true)
        if response.instance_of?(Net::HTTPBadRequest)
          raise ProjectHanlon::Error::Slice::CommandFailed, result["result"]["description"]
        end
        slice_success(result, :success_type => :removed)
      end

      def get_logs
        @command = :get_logs
        uri = URI.parse(@uri_string + '/logs')
        # and get the results of the appropriate RESTful request using that URI
        include_http_response = true
        result, response = rz_http_get(uri, include_http_response)
        if response.instance_of?(Net::HTTPBadRequest)
          raise ProjectHanlon::Error::Slice::CommandFailed, result["result"]["description"]
        end
        # finally, based on the options selected, print the results
        lcl_slice_obj_ref = ProjectHanlon::PolicyTemplate::Base.new({})
        print_object_array(lcl_slice_obj_ref.print_log_all(result), "All Active Model Logs:", :style => :table)
      end

    end
  end
end


