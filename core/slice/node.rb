require 'net/http'

# Root ProjectHanlon namespace
module ProjectHanlon
  class Slice

    # ProjectHanlon Slice Node (NEW)
    # Used for policy management
    class Node < ProjectHanlon::Slice

      # @param [Array] args
      def initialize(args)
        super(args)
        @hidden     = false
        @engine     = ProjectHanlon::Engine.instance
        @uri_string = ProjectHanlon.config.hanlon_uri + ProjectHanlon.config.websvc_root + '/node'

      end

      def slice_commands
        # get the slice commands map for this slice (based on the set
        # of commands that are typical for most slices); note that there is
        # no support for adding, updating, or removing nodes via the slice
        # API, so the last three arguments are nil
        commands = get_command_map("node_help", "get_all_nodes",
                                   "get_node_by_uuid", nil, nil, nil, nil)
        # and add a few more commands specific to this slice
        commands[:get][/^(?!^(all|\-\-help|\-h|\{\}|\{.*\}|nil)$)\S+$/][:else] = "get_node_by_uuid"
        commands
      end

      def all_command_option_data
        {
            :get => [
                { :name        => :field,
                  :default     => nil,
                  :short_form  => '-f',
                  :long_form   => '--field FIELD_NAME',
                  :description => 'The fieldname (attributes or hardware_id) to get',
                  :uuid_is     => 'required',
                  :required    => false
                }
            ]
        }.freeze
      end

      def node_help
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
        puts get_node_help
      end

      def get_node_help
        return ["Node Slice: used to view the current list of nodes (or node details)".red,
                "Node Commands:".yellow,
                "\thanlon node [get] [all]                      " + "Display list of nodes".yellow,
                "\thanlon node [get] (UUID)                     " + "Display details for a node".yellow,
                "\thanlon node [get] (UUID) [--field,-f FIELD]  " + "Display node's field values".yellow,
                "\thanlon node --help                           " + "Display this screen".yellow,
                "  Note; the FIELD value (above) can be either 'attributes' or 'hardware_ids'".red].join("\n")
      end

      def get_all_nodes
        # Get all node instances and print/return
        @command = :get_all_nodes
        raise ProjectHanlon::Error::Slice::SliceCommandParsingFailed,
              "Unexpected arguments found in command #{@command} -> #{@command_array.inspect}" if @command_array.length > 0
        uri = URI.parse @uri_string
        node_array = hash_array_to_obj_array(expand_response_with_uris(hnl_http_get(uri)))
        print_object_array(node_array, "Discovered Nodes", :style => :table)
      end

      def get_node_by_uuid
        @command = :get_node_by_uuid
        includes_uuid = false
        # load the appropriate option items for the subcommand we are handling
        option_items = command_option_data(:get)
        # parse and validate the options that were passed in as part of this
        # subcommand (this method will return a UUID value, if present, and the
        # options map constructed from the @commmand_array)
        node_uuid, options = parse_and_validate_options(option_items, "hanlon node [get] (UUID) [--field,-f FIELD]", :require_all)
        includes_uuid = true if node_uuid
        selected_option = options[:field]
        # setup the proper URI depending on the options passed in
        uri = URI.parse(@uri_string + '/' + node_uuid)
        print_node_attributes = false
        if selected_option
          if /^(attrib|attributes)$/.match(selected_option)
            print_node_attributes = true
          elsif !/^(hardware|hardware_id|hardware_ids)$/.match(selected_option)
            raise ProjectHanlon::Error::Slice::InputError, "unrecognized fieldname '#{selected_option}'"
          end
        end
        # and get the results of the appropriate RESTful request using that URI
        include_http_response = true
        result, response = hnl_http_get(uri, include_http_response)
        if response.instance_of?(Net::HTTPBadRequest)
          raise ProjectHanlon::Error::Slice::CommandFailed, result["result"]["description"]
        end
        # finally, based on the options selected, print the results
        return print_object_array(hash_array_to_obj_array([result]), "Node:") unless selected_option
        if print_node_attributes
          return print_object_array(hash_to_obj(result).print_attributes_hash, "Node Attributes:")
        end
        print_object_array(hash_to_obj(result).print_hardware_ids, "Node Hardware ID:")
      end

    end
  end
end


