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
        # the other four flags we might pass in as part of a "get_all_active_models" command
        commands[:get][/^(?!^(all|\-\-hw_id|\-i|\-\-node_uuid|\-n|\-\-help|\-h|\{\}|\{.*\}|nil)$)\S+$/] = tmp_map
        # and add in a couple of lines that handle those four flags properly
        [["-i", "--hw_id"], ["-n", "--node_uuid"]].each { |val|
          commands[:get][val] = "get_all_active_models"
        }

        # next, remove the default line that handles the commands where the user is wanting to
        # remove an active_model instance by (active_model) uuid
        tmp_map = commands[:remove][/^(?!^(all|\-\-help|\-h)$)\S+$/]
        commands[:remove].delete(/^(?!^(all|\-\-help|\-h)$)\S+$/)
        # then add a slightly different version of this line back in; one that incorporates
        # the other four flags we might pass in as part of a "remove_active_model_by_uuid" command
        commands[:remove][/^(?!^(all|\-\-hw_id|\-i|\-\-node_uuid|\-n|\-\-help|\-h)$)\S+$/] = tmp_map
        # and add in a couple of lines that handle those four flags properly
        [["-i", "--hw_id"], ["-n", "--node_uuid"]].each { |val|
          commands[:remove][val] = "remove_active_model_by_uuid"
        }

        # finally, add in a couple of lines to properly handle "get_active_model_logs" commands
        commands[:logs] = "get_logs"
        commands[:logs][/^(?!^(\-\-hw_id|\-i|\-\-node_uuid|\-n|\{\}|\{.*\}|nil)$)\S+$/] = "get_active_model_logs"
        commands[:get][/^(?!^(all|\-\-hw_id|\-i|\-\-node_uuid|\-n|\-\-help|\-h|\{\}|\{.*\}|nil)$)\S+$/][:logs] = "get_active_model_logs"

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
        puts "Active Model Slice: used to view active models or active model logs (and to remove active models).".red
        puts "Active Model Commands:".yellow
        puts "\thanlon active_model [get] [all]                            " + "View all active models".yellow
        puts "\thanlon active_model [get] (UUID) [logs]                    " + "View specific active model (log)".yellow
        puts "\thanlon active_model [get] --node_uuid,-n NODE_UUID [logs]  " + "View (log for) active_model bound to node".yellow
        puts "\thanlon active_model [get] --hw_id,-i HW_ID [logs]          " + "View (log for) active_model bound to node".yellow
        puts "\thanlon active_model logs                                   " + "Prints an aggregate view of active model logs".yellow
        puts "\thanlon active_model remove (UUID)                          " + "Remove specific active model".yellow
        puts "\thanlon active_model remove --node_uuid,-n NODE_UUID        " + "Remove active_model bound to node".yellow
        puts "\thanlon active_model remove --hw_id,-i HW_ID                " + "Remove active_model bound to node".yellow
        puts "\thanlon active_model --help|-h                              " + "Display this screen".yellow
      end

      def get_all_active_models
        @command = :get_all_active_models
        # when we get here, should be zero, one, or two elements in the @command_array Array (depending
        # on whether we included a hardware_id or node_uuid value to match in the command to get all nodes
        # and, if a hardware_id or node_uuid was provided, whether the user is actually looking for the
        # logs associated with the active_model bound to that node)
        get_logs_flag = false
        if @command_array.size < 3
          prev_flag = @prev_args.peek(0)
          hardware_id = @command_array[0] if prev_flag && ['--hw_id','-i'].include?(prev_flag)
          node_uuid = @command_array[0] if prev_flag && ['--node_uuid','-n'].include?(prev_flag)
          if @command_array.size == 2 && @command_array[1] == 'logs'
            get_logs_flag = true
          end
        else
          raise ProjectHanlon::Error::Slice::SliceCommandParsingFailed,
                "Unexpected arguments found in command #{@command} -> #{@command_array.inspect}"
        end
        # if a hardware ID was passed in, then append it to the @uri_string and return the result,
        # else just get the list of all nodes and return that result
        if hardware_id || node_uuid
          uri = URI.parse(@uri_string + "?hw_id=#{hardware_id}") if hardware_id
          uri = URI.parse(@uri_string + "?node_uuid=#{node_uuid}") if node_uuid
          # and get the results of the appropriate RESTful request using that URI
          result = hnl_http_get(uri)
          # if user was actually looking for logs, then return the logs
          if get_logs_flag
            # convert the result into an active_model instance, then use that instance to
            # print out the logs for that instance
            active_model_ref = hash_to_obj(result)
            return print_object_array(active_model_ref.print_log, "", :style => :table)
          end
          # otherwise, return the result as an object array
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
        # the UUID was the last "previous argument"
        active_model_uuid = @prev_args.peek(0)
        # setup the proper URI depending on the options passed in
        uri = URI.parse(@uri_string + '/' + active_model_uuid)
        # and get the results of the appropriate RESTful request using that URI
        result = hnl_http_get(uri)
        # finally, based on the options selected, print the results
        print_object_array(hash_array_to_obj_array([result]), "Active Model:")
      end

      def get_active_model_logs
        @command = :get_active_model_logs
        # if there are still arguments left, then user was looking for the logs for
        # a specific active_model instance (based on the hardware_id or node_uuid
        # of the node that active_model is bound to), to print that
        if @command_array.size == 2
          node_sel_flag = @command_array[0]
          hardware_id = @command_array[1] if ['--hw_id','-i'].include?(node_sel_flag)
          node_uuid = @command_array[1] if ['--node_uuid','-n'].include?(node_sel_flag)
          if hardware_id || node_uuid
            uri = URI.parse(@uri_string + "?hw_id=#{hardware_id}") if hardware_id
            uri = URI.parse(@uri_string + "?node_uuid=#{node_uuid}") if node_uuid
            # and get the results of the appropriate RESTful request using that URI
            result = hnl_http_get(uri)
          else
            raise ProjectHanlon::Error::Slice::SliceCommandParsingFailed,
                  "Unexpected arguments found in command #{@command} -> #{@command_array.inspect}"
          end
        elsif @command_array.size == 0
          # if we get this far, then the user was looking for the active_model logs for
          # a specific active_model (based on the UUID of that active_model instance);
          # in that case, the UUID is the top element of the @prev_args stack
          uuid = @prev_args.peek(1)
          # catches the case where a UUID was not included
          return get_logs unless uuid
          # setup a URI to retrieve the active_model in question
          uri = URI.parse(@uri_string + '/' + uuid)
          # and get the results of the appropriate RESTful request using that URI
          result = hnl_http_get(uri)
        else
          raise ProjectHanlon::Error::Slice::SliceCommandParsingFailed,
                "Unexpected arguments found in command #{@command} -> #{@command_array.inspect}"
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
        prev_flag = @prev_args.peek(0)
        hardware_id = @command_array[0] if prev_flag && ['--hw_id','-i'].include?(prev_flag)
        node_uuid = @command_array[0] if prev_flag && ['--node_uuid','-n'].include?(prev_flag)
        if hardware_id || node_uuid
          uri = URI.parse(@uri_string + "?hw_id=#{hardware_id}") if hardware_id
          uri = URI.parse(@uri_string + "?node_uuid=#{node_uuid}") if node_uuid
        else
          # the UUID was the last "previous argument"
          active_model_uuid = @prev_args.peek(0)
          # setup the DELETE (to update the remove the indicated active_model) and return the results
          uri = URI.parse(@uri_string + '/' + active_model_uuid)
        end
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


