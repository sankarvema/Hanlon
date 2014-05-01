require "json"
require "project_hanlon/broker/base"

# Root ProjectHanlon namespace
module ProjectHanlon
  class Slice

    # ProjectHanlon Slice Broker
    # Used for broker management
    class Broker < ProjectHanlon::Slice

      # Root namespace for broker objects; used to find them
      # in object space in order to gather meta-data for creating brokers
      SLICE_BROKER_PREFIX = "ProjectHanlon::BrokerPlugin::"

      # Initializes ProjectHanlon::Slice::Broker including #slice_commands, #slice_commands_help
      # @param [Array] args
      def initialize(args)
        super(args)
        @hidden          = false
        @uri_string = ProjectHanlon.config.hanlon_uri + ProjectHanlon.config.websvc_root + '/broker'
      end

      def slice_commands
        # get the slice commands map for this slice (based on the set
        # of commands that are typical for most slices)
        commands = get_command_map(
            "broker_help",
            "get_all_brokers",
            "get_broker_by_uuid",
            "add_broker",
            "update_broker",
            "remove_all_brokers",
            "remove_broker_by_uuid")

        commands[:get].delete(/^(?!^(all|\-\-help|\-h|\{\}|\{.*\}|nil)$)\S+$/)
        commands[:get][:else] = "get_broker_by_uuid"
        commands[:get][[/^(plugin|plugins|t)$/]] = "get_broker_plugins"

        commands
      end

      def all_command_option_data
        {
            :add => [
                { :name        => :plugin,
                  :default     => false,
                  :short_form  => '-p',
                  :long_form   => '--plugin BROKER_PLUGIN',
                  :description => 'The broker plugin to use.',
                  :uuid_is     => 'not_allowed',
                  :required    => true
                },
                { :name        => :name,
                  :default     => false,
                  :short_form  => '-n',
                  :long_form   => '--name BROKER_NAME',
                  :description => 'The name for the broker target.',
                  :uuid_is     => 'not_allowed',
                  :required    => true
                },
                { :name        => :description,
                  :default     => false,
                  :short_form  => '-d',
                  :long_form   => '--description DESCRIPTION',
                  :description => 'A description for the broker target.',
                  :uuid_is     => 'not_allowed',
                  :required    => true
                }
            ],
            :update  =>  [
                { :name        => :name,
                  :default     => false,
                  :short_form  => '-n',
                  :long_form   => '--name BROKER_NAME',
                  :description => 'New name for the broker target.',
                  :uuid_is     => 'required',
                  :required    => true
                },
                { :name        => :description,
                  :default     => false,
                  :short_form  => '-d',
                  :long_form   => '--description DESCRIPTION',
                  :description => 'New description for the broker target.',
                  :uuid_is     => 'required',
                  :required    => true
                },
                { :name        => :change_metadata,
                  :default     => false,
                  :short_form  => '-c',
                  :long_form   => '--change-metadata',
                  :description => 'Used to trigger a change in the broker\'s meta-data',
                  :uuid_is     => 'required',
                  :required    =>true
                }
            ]
        }.freeze
      end

      def broker_help
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
        puts "Broker Slice: used to add, view, update, and remove Broker Targets.".red
        puts "Broker Commands:".yellow
        puts "\thanlon broker [get] [all]                 " + "View all broker targets".yellow
        puts "\thanlon broker [get] (UUID)                " + "View specific broker target".yellow
        puts "\thanlon broker [get] plugin|plugins|t      " + "View list of available broker plugins".yellow
        puts "\thanlon broker add (options...)            " + "Create a new broker target".yellow
        puts "\thanlon broker update (UUID) (options...)  " + "Update a specific broker target".yellow
        puts "\thanlon broker remove (UUID)|all           " + "Remove existing (or all) broker target(s)".yellow
        puts "\thanlon broker --help|-h                   " + "Display this screen".yellow
      end

      # Returns all broker instances
      def get_all_brokers
        @command = :get_all_brokers
        uri = URI.parse @uri_string
        broker_array = hash_array_to_obj_array(expand_response_with_uris(rz_http_get(uri)))
        print_object_array(broker_array, "Broker Targets:", :style => :table)
      end

      # Returns the broker plugins available
      def get_broker_plugins
        @command = :get_broker_plugins
        uri = URI.parse @uri_string + '/plugins'
        broker_plugins = hash_array_to_obj_array(expand_response_with_uris(rz_http_get(uri)))
        print_object_array(broker_plugins, "Available Broker Plugins:")
      end

      def get_broker_by_uuid
        @command = :get_broker_by_uuid
        # the UUID is the first element of the @command_array
        broker_uuid = @command_array.first
        # setup the proper URI depending on the options passed in
        uri = URI.parse(@uri_string + '/' + broker_uuid)
        # and get the results of the appropriate RESTful request using that URI
        include_http_response = true
        result, response = rz_http_get(uri, include_http_response)
        if response.instance_of?(Net::HTTPBadRequest)
          raise ProjectHanlon::Error::Slice::CommandFailed, result["result"]["description"]
        end
        # finally, based on the options selected, print the results
        print_object_array(hash_array_to_obj_array([result]), "Broker:")
      end

      def add_broker
        @command = :add_broker
        includes_uuid = false
        # load the appropriate option items for the subcommand we are handling
        option_items = command_option_data(:add)
        # parse and validate the options that were passed in as part of this
        # subcommand (this method will return a UUID value, if present, and the
        # options map constructed from the @commmand_array)
        tmp, options = parse_and_validate_options(option_items, "hanlon broker add (options...)", :require_all)
        includes_uuid = true if tmp && tmp != "add"
        # check for usage errors (the boolean value at the end of this method
        # call is used to indicate whether the choice of options from the
        # option_items hash must be an exclusive choice)
        check_option_usage(option_items, options, includes_uuid, false)
        # use the arguments passed in to create a new broker
        broker = new_object_from_template_name(SLICE_BROKER_PREFIX, options[:plugin])
        broker.cli_create_metadata
        # setup the POST (to create the requested broker) and return the results
        uri = URI.parse @uri_string
        body_hash = {
            "name" => options[:name],
            "description" => options[:description],
            "plugin" => options[:plugin],
            "req_metadata_hash" => broker.req_metadata_hash
        }
        broker.req_metadata_hash.each { |key, md_hash_value|
          value = broker.instance_variable_get(key)
          body_hash[key] = value
        }
        json_data = body_hash.to_json
        result, response = rz_http_post_json_data(uri, json_data, true)
        if response.instance_of?(Net::HTTPBadRequest)
          raise ProjectHanlon::Error::Slice::CommandFailed, result["result"]["description"]
        end
        print_object_array(hash_array_to_obj_array([result]), "Broker Created:")
      end

      def update_broker
        @command = :update_broker
        includes_uuid = false
        # load the appropriate option items for the subcommand we are handling
        option_items = command_option_data(:update)
        # parse and validate the options that were passed in as part of this
        # subcommand (this method will return a UUID value, if present, and the
        # options map constructed from the @commmand_array)
        broker_uuid, options = parse_and_validate_options(option_items, "hanlon broker update (UUID) (options...)", :require_one)
        includes_uuid = true if broker_uuid
        # check for usage errors (the boolean value at the end of this method
        # call is used to indicate whether the choice of options from the
        # option_items hash must be an exclusive choice)
        check_option_usage(option_items, options, includes_uuid, false)
        name = options[:name]
        description = options[:description]
        change_metadata = options[:change_metadata]
        # now, use the values that were passed in to update the indicated broker
        uri = URI.parse(@uri_string + '/' + broker_uuid)
        # and get the results of the appropriate RESTful request using that URI
        include_http_response = true
        result, response = rz_http_get(uri, include_http_response)
        if response.instance_of?(Net::HTTPBadRequest)
          raise ProjectHanlon::Error::Slice::CommandFailed, result["result"]["description"]
        end
        broker = hash_to_obj(result)
        # if the user requested a change to the meta-data hash associated with the
        # indicated broker, then gather that new meta-data from the user
        if change_metadata
          raise ProjectHanlon::Error::Slice::UserCancelled, "User cancelled Broker creation" unless
              broker.cli_create_metadata
        end
        # add properties passed in from command line to the json_data
        # hash that we'll be passing in as the body of the request
        body_hash = {}
        body_hash["name"] = name if name
        body_hash["description"] = description if description
        if change_metadata
          broker.req_metadata_hash.each { |key, md_hash_value|
            value = broker.instance_variable_get(key)
            body_hash[key] = value
          }
          body_hash["req_metadata_hash"] = broker.req_metadata_hash
        end
        json_data = body_hash.to_json
        # setup the PUT (to update the indicated broker) and return the results
        result, response = rz_http_put_json_data(uri, json_data, true)
        if response.instance_of?(Net::HTTPBadRequest)
          raise ProjectHanlon::Error::Slice::CommandFailed, result["result"]["description"]
        end
        print_object_array(hash_array_to_obj_array([result]), "Broker Updated:")
      end

      def remove_broker
        @command = :remove_broker
        # load the appropriate option items for the subcommand we are handling
        option_items = command_option_data(:remove)
        # parse and validate the options that were passed in as part of this
        # subcommand (this method will return a UUID value, if present, and the
        # options map constructed from the @commmand_array)
        broker_uuid, options = parse_and_validate_options(option_items, "hanlon broker remove (UUID)|(--all)", :require_all)
        if !@web_command
          broker_uuid = @command_array.shift
        end
        includes_uuid = true if broker_uuid
        # check for usage errors (the boolean value at the end of this method
        # call is used to indicate whether the choice of options from the
        # option_items hash must be an exclusive choice)
        check_option_usage(option_items, options, includes_uuid, true)
        # and then invoke the right method (based on usage)
        # selected_option = options.select { |k, v| v }.keys[0].to_s
        if options[:all]
          # remove all Brokers from the system
          remove_all_brokers
        elsif includes_uuid
          # remove a specific Broker (by UUID)
          remove_broker_with_uuid(broker_uuid)
        else
          # if get to here, no UUID was specified and 'all' was to used to try to
          # remove all brokers from the system no included, so raise an error and exit
          raise ProjectHanlon::Error::Slice::MissingArgument, "Must provide a UUID for the broker to remove (or 'all' to remove all)"
        end
      end

      def remove_all_brokers
        @command = :remove_all_brokers
        raise ProjectHanlon::Error::Slice::MethodNotAllowed, "This method has been deprecated"
      end

      def remove_broker_by_uuid
        @command = :remove_broker_by_uuid
        # the UUID is the first element of the @command_array
        broker_uuid = get_uuid_from_prev_args
        # setup the DELETE (to remove the indicated broker) and return the results
        uri = URI.parse @uri_string + "/#{broker_uuid}"
        result, response = rz_http_delete(uri, true)
        if response.instance_of?(Net::HTTPBadRequest)
          raise ProjectHanlon::Error::Slice::CommandFailed, result["result"]["description"]
        end
        slice_success(result, :success_type => :removed)
      end

    end
  end
end
