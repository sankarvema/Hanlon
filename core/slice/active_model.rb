require "json"
require "policy/base"

# Root ProjectHanlon namespace
module ProjectHanlon
  class Slice

    # ProjectHanlon Slice Active_Model
    class ActiveModel < ProjectHanlon::Slice

      def initialize(args)
        super(args)
        @hidden     = false
        @policies   = ProjectHanlon::Policies.instance
        @uri_string = ProjectHanlon.config.hanlon_uri + ProjectHanlon.config.websvc_root + '/active_model'
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

        # and add a few more commands specific to this slice; first remove the default line that
        # handles the lines where a UUID is passed in as part of a "get_active_model_by_uuid" command
        tmp_map = commands[:get][/^(?!^(all|\-\-help|\-h|\{\}|\{.*\}|nil)$)\S+$/]
        commands[:get].delete(/^(?!^(all|\-\-help|\-h|\{\}|\{.*\}|nil)$)\S+$/)
        # then add a slightly different version of this line back in; one that incorporates
        # the other two flags we might pass in as part of a "get_all_active_models" command
        commands[:get][/^(?!^(all|\-\-hw_id|\-i|\-\-help|\-h|\{\}|\{.*\}|nil)$)\S+$/] = tmp_map
        # and add in a line that handles those two flags properly
        commands[:get][["-i", "--hw_id"]] = "get_all_active_models"
        # finally, add in a couple of lines to properly handle "get_active_model_logs" commands
        commands[:logs] = "get_logs"
        commands[:get][/^(?!^(all|\-\-hw_id|\-i|\-\-help|\-h|\{\}|\{.*\}|nil)$)\S+$/][:logs] = "get_active_model_logs"

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
            # ignored
          end
        end
        # if here, then either there are no specific options for the current command or we've
        # been asked for generic help, so provide generic help
        puts "Active Model Slice: used to view active models or active model logs, and to remove active models.".red
        puts "Active Model Commands:".yellow
        puts "\thanlon active_model [get] [all] [--hw_id,-i HW_ID] " + "View all active models".yellow
        puts "\thanlon active_model [get] (UUID) [logs]            " + "View specific active model (log)".yellow
        puts "\thanlon active_model logs                           " + "Prints an aggregate view of active model logs".yellow
        puts "\thanlon active_model remove (UUID)|all              " + "Remove existing (or all) active model(s)".yellow
        puts "\thanlon active_model --help|-h                      " + "Display this screen".yellow
      end

      def get_all_active_models
        @command = :get_all_active_models
        # when we get here, should be zero or one elements in the @command_array Array (depending
        # on whether we included a hardware_id value to match in the command to get all nodes)
        raise ProjectHanlon::Error::Slice::SliceCommandParsingFailed,
              "Unexpected arguments found in command #{@command} -> #{@command_array.inspect}" if @command_array.length > 1
        hardware_id = @command_array[0] if @command_array
        # if a hardware ID was passed in, then append it to the @uri_string and return the result,
        # else just get the list of all nodes and return that result
        if hardware_id
          uri = URI.parse(@uri_string + "?uuid=#{hardware_id}")
          # and get the results of the appropriate RESTful request using that URI
          result = hnl_http_get(uri)
          return print_object_array(hash_array_to_obj_array([result]), "Active Model:")
        end
        # get the active models from the RESTful API (as an array of objects)
        uri = URI.parse @uri_string
        result = hnl_http_get(uri)
        unless result.blank?
          # convert it to a sorted array of objects (from an array of hashes)
          sort_fieldname = 'node_uuid'
          result = hash_array_to_obj_array(expand_response_with_uris(result), sort_fieldname)
        end
        # and print the result
        print_object_array(result, "Active Models:", :style => :table)
      end

      def get_active_model_by_uuid
        @command = :get_active_model_by_uuid
        # the UUID is the first element of the @command_array
        uuid = get_uuid_from_prev_args
        # setup the proper URI depending on the options passed in
        uri = URI.parse(@uri_string + '/' + uuid)
        # and get the results of the appropriate RESTful request using that URI
        result = hnl_http_get(uri)
        # finally, based on the options selected, print the results
        print_object_array(hash_array_to_obj_array([result]), "Active Model:")
      end

      def get_active_model_logs
        @command = :get_active_model_logs
        # the UUID is the first element of the @command_array
        uuid = @prev_args.peek(1)
        # setup a URI to retrieve the active_model in question
        uri = URI.parse(@uri_string + '/' + uuid)
        # and get the results of the appropriate RESTful request using that URI
        result = hnl_http_get(uri)
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
        result = hnl_http_delete(uri)
        slice_success(result, :success_type => :removed)
      end

      def get_logs
        @command = :get_logs
        uri = URI.parse(@uri_string + '/logs')
        # and get the results of the appropriate RESTful request using that URI
        result = hnl_http_get(uri)
        # finally, based on the options selected, print the results
        lcl_slice_obj_ref = ProjectHanlon::PolicyTemplate::Base.new({})
        print_object_array(lcl_slice_obj_ref.print_log_all(result), "All Active Model Logs:", :style => :table)
      end

    end
  end
end


