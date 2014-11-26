
# Root ProjectHanlon namespace
module ProjectHanlon
  class Slice

    # ProjectHanlon Slice Tag
    # Used for managing the tagging system
    class Tag < ProjectHanlon::Slice
      # Initializes ProjectHanlon::Slice::Tag
      # @param [Array] args
      def initialize(args)
        super(args)
        @hidden = false
        @uri_string = ProjectHanlon.config.hanlon_uri + ProjectHanlon.config.websvc_root + '/tag'
      end

      def slice_commands
        # get the slice commands map for this slice (based on the set
        # of commands that are typical for most slices)
        commands = get_command_map("tag_help",
                                   "get_all_tagrules",
                                   "get_tagrule_by_uuid",
                                   "add_tagrule",
                                   "update_tagrule",
                                   "remove_all_tagrules",
                                   "remove_tagrule_by_uuid")
        # and add the corresponding 'matcher' commands to the set of slice_commands
        tag_uuid_match = /^((?!(matcher|add|get|all|remove|update|default)))\S+/
        commands[tag_uuid_match] = {}
        commands[tag_uuid_match][:default] = "get_tagrule_by_uuid"
        commands[tag_uuid_match][:else] = "get_tagrule_by_uuid"
        commands[tag_uuid_match][:matcher] = {}
        # add a few more commands to support the use of "tag matcher" help without
        # having to include a tag UUID in the help command (i.e. commands like
        # "hanlon tag matcher update --help" or "hanlon tag matcher add --help")
        commands[:matcher] = {}
        commands[:matcher][:else] = "tag_help"
        commands[:matcher][:default] = "tag_help"
        # adding a tag matcher
        commands[tag_uuid_match][:matcher][:add] = {}
        commands[tag_uuid_match][:matcher][:add][/^(--help|-h)$/] = "tag_help"
        commands[tag_uuid_match][:matcher][:add][:default] = "tag_help"
        commands[tag_uuid_match][:matcher][:add][:else] = "add_matcher"
        # add support for the "tag matcher update help" commands
        commands[:matcher][:add] = {}
        commands[:matcher][:add][/^(--help|-h)$/] = "tag_help"
        commands[:matcher][:add][:default] = "throw_syntax_error"
        commands[:matcher][:add][:else] = "throw_syntax_error"
        # updating a tag matcher
        commands[tag_uuid_match][:matcher][:update] = {}
        commands[tag_uuid_match][:matcher][:update][/^(--help|-h)$/] = "tag_help"
        commands[tag_uuid_match][:matcher][:update][:default] = "tag_help"
        commands[tag_uuid_match][:matcher][:update][/^(?!^(all|\-\-help|\-h)$)\S+$/] = "update_matcher"
        # add support for the "tag matcher update help" commands
        commands[:matcher][:update] = {}
        commands[:matcher][:update][/^(--help|-h)$/] = "tag_help"
        commands[:matcher][:update][:default] = "throw_syntax_error"
        commands[:matcher][:update][:else] = "throw_syntax_error"
        # removing a tag matcher
        commands[tag_uuid_match][:matcher][:remove] = {}
        commands[tag_uuid_match][:matcher][:remove][/^(--help|-h)$/] = "tag_help"
        commands[tag_uuid_match][:matcher][:remove][:default] = "tag_help"
        commands[tag_uuid_match][:matcher][:remove][/^(?!^(all|\-\-help|\-h)$)\S+$/] = "remove_matcher"
        # add support for the "tag matcher remove help" commands
        commands[:matcher][:remove] = {}
        commands[:matcher][:remove][/^(--help|-h)$/] = "tag_help"
        commands[:matcher][:remove][:default] = "throw_syntax_error"
        commands[:matcher][:remove][:else] = "throw_syntax_error"
        # getting a tag matcher
        tag_matcher_uuid_match = /^((?!(add|get|all|remove|update|default)))\S+/
        commands[tag_uuid_match][:matcher][tag_matcher_uuid_match] = "get_matcher_by_uuid"
        commands[tag_uuid_match][:matcher][:else] = "get_matchers_for_tagrule"
        commands[tag_uuid_match][:matcher][:default] = "get_matchers_for_tagrule"

        commands
      end

      def all_command_option_data
        {
            :add => [
                { :name        => :name,
                  :default     => false,
                  :short_form  => '-n',
                  :long_form   => '--name NAME',
                  :description => 'Name for the tagrule being created',
                  :uuid_is     => 'not_allowed',
                  :required    => true
                },
                { :name        => :tag,
                  :default     => false,
                  :short_form  => '-t',
                  :long_form   => '--tag TAG',
                  :description => 'Tag for the tagrule being created',
                  :uuid_is     => 'not_allowed',
                  :required    => true
                }
            ],
            :update => [
                { :name        => :name,
                  :default     => nil,
                  :short_form  => '-n',
                  :long_form   => '--name NAME',
                  :description => 'New name for the tagrule being updated.',
                  :uuid_is     => 'required',
                  :required    => true
                },
                { :name        => :tag,
                  :default     => nil,
                  :short_form  => '-t',
                  :long_form   => '--tag TAG',
                  :description => 'New tag for the tagrule being updated.',
                  :uuid_is     => 'required',
                  :required    => true
                }
            ],
            :add_matcher => [
                { :name        => :key,
                  :default     => nil,
                  :short_form  => '-k',
                  :long_form   => '--key KEY_FIELD',
                  :description => 'The node attribute key to match against.',
                  :uuid_is     => 'not_allowed',
                  :required    => true
                },
                { :name        => :compare,
                  :default     => nil,
                  :short_form  => '-c',
                  :long_form   => '--compare METHOD',
                  :description => 'The comparison method to use (\'equal\'|\'like\').',
                  :uuid_is     => 'not_allowed',
                  :required    => true
                },
                { :name        => :value,
                  :default     => nil,
                  :short_form  => '-v',
                  :long_form   => '--value VALUE',
                  :description => 'The value to match against',
                  :uuid_is     => 'not_allowed',
                  :required    => true
                },
                { :name        => :inverse,
                  :default     => nil,
                  :short_form  => '-i',
                  :long_form   => '--inverse VALUE',
                  :description => 'Inverse the match (true if key does not match value).',
                  :uuid_is     => 'not_allowed',
                  :required    => false
                }
            ],
            :update_matcher => [
                { :name        => :key,
                  :default     => nil,
                  :short_form  => '-k',
                  :long_form   => '--key KEY_FIELD',
                  :description => 'The new node attribute key to match against.',
                  :uuid_is     => 'required',
                  :required    => true
                },
                { :name        => :compare,
                  :default     => nil,
                  :short_form  => '-c',
                  :long_form   => '--compare METHOD',
                  :description => 'The new comparison method to use (\'equal\'|\'like\').',
                  :uuid_is     => 'required',
                  :required    => true
                },
                { :name        => :value,
                  :default     => nil,
                  :short_form  => '-v',
                  :long_form   => '--value VALUE',
                  :description => 'The new value to match against.',
                  :uuid_is     => 'required',
                  :required    => true
                },
                { :name        => :inverse,
                  :default     => nil,
                  :short_form  => '-i',
                  :long_form   => '--inverse VALUE',
                  :description => 'Inverse the match (true|false).',
                  :uuid_is     => 'required',
                  :required    => true
                }
            ]
        }.freeze
      end

      def tag_help
        if @prev_args.length > 1
          # get the command name that should be used to load the right options
          command = (@prev_args.include?("matcher") ? "#{@prev_args.peek(1)}_matcher": @prev_args.peek(1))
          begin
            # load the option items for this command (if they exist) and print them; note that
            # the command update_matcher (or add_matcher) actually appears on the CLI as
            # the command hanlon tag (UUID) matcher update (or add), so need to split on the
            # underscore character and swap the order when printing the command usage
            option_items = command_option_data(command)
            command, subcommand = command.split("_")
            if subcommand
              print_subcommand_help(command, subcommand, option_items)
            else
              print_command_help(command, option_items)
            end
            return
          rescue
          end
        end
        # if here, then either there are no specific options for the current command or we've
        # been asked for generic help, so provide generic help
        puts get_tag_help
      end

      def get_tag_help
        return [ "Tag Slice:".red,
                 "Used to view, create, update, and remove Tags and Tag Matchers.".red,
                 "Tag commands:".yellow,
                 "\thanlon tag [get] [all]                           " + "View Tag summary".yellow,
                 "\thanlon tag [get] (UUID)                          " + "View details of a Tag".yellow,
                 "\thanlon tag add (...)                             " + "Create a new Tag".yellow,
                 "\thanlon tag update (UUID) (...)                   " + "Update an existing Tag ".yellow,
                 "\thanlon tag remove (UUID)|all                     " + "Remove existing Tag(s)".yellow,
                 "Tag Matcher commands:".yellow,
                 "\thanlon tag (T_UUID) matcher [get] [all]          " + "View Tag Matcher summary".yellow,
                 "\thanlon tag (T_UUID) matcher [get] (UUID)         " + "View Tag Matcher details".yellow,
                 "\thanlon tag (T_UUID) matcher add (...)            " + "Create a new Tag Matcher".yellow,
                 "\thanlon tag (T_UUID) matcher update (UUID) (...)  " + "Update a Tag Matcher".yellow,
                 "\thanlon tag (T_UUID) matcher remove (UUID)        " + "Remove a Tag Matcher".yellow,
                 "\thanlon tag --help|-h                             " + "Display this screen".yellow].join("\n")
      end

      def get_all_tagrules
        @command = :get_all_tagrules
        # get the tagrules from the RESTful API (as an array of objects)
        uri = URI.parse @uri_string
        result = hnl_http_get(uri)
        unless result.blank?
          # convert it to a sorted array of objects (from an array of hashes)
          sort_fieldname = 'name'
          result = hash_array_to_obj_array(expand_response_with_uris(result), sort_fieldname)
        end
        # and print the result
        print_object_array(result, "Tag Rules:", :style => :table)
      end

      def get_tagrule_by_uuid
        @command = :get_tagrule_by_uuid
        # the UUID was the last "previous argument"
        tagrule_uuid = @prev_args.peek(0)
        # setup the proper URI depending on the options passed in
        uri = URI.parse(@uri_string + '/' + tagrule_uuid)
        # and get the results of the appropriate RESTful request using that URI
        result = hnl_http_get(uri)
        # finally, based on the options selected, print the results
        print_object_array(hash_array_to_obj_array([result]), "Tag Rule:")
      end

      def add_tagrule
        @command = :add_tagrule
        includes_uuid = false
        # load the appropriate option items for the subcommand we are handling
        option_items = command_option_data(:add)
        # parse and validate the options that were passed in as part of this
        # subcommand (this method will return a UUID value, if present, and the
        # options map constructed from the @commmand_array)
        tmp, options = parse_and_validate_options(option_items, :require_all, :banner => "hanlon tag add (options...)")
        includes_uuid = true if tmp && tmp != "add"
        # check for usage errors (the boolean value at the end of this method
        # call is used to indicate whether the choice of options from the
        # option_items hash must be an exclusive choice)
        check_option_usage(option_items, options, includes_uuid, false)
        # setup the POST (to create the requested policy) and return the results
        uri = URI.parse @uri_string
        json_data = {
            "name" => options[:name],
            "tag" => options[:tag]
        }.to_json
        result = hnl_http_post_json_data(uri, json_data)
        print_object_array(hash_array_to_obj_array([result]), "Tag Rule Created:")
      end

      def update_tagrule
        @command = :update_tagrule
        includes_uuid = false
        # load the appropriate option items for the subcommand we are handling
        option_items = command_option_data(:update)
        # parse and validate the options that were passed in as part of this
        # subcommand (this method will return the options map constructed
        # from the @commmand_array)
        tagrule_uuid, options = parse_and_validate_options(option_items, :require_one, :banner => "hanlon tag update (UUID) (options...)")
        includes_uuid = true if tagrule_uuid
        # check for usage errors (the boolean value at the end of this method
        # call is used to indicate whether the choice of options from the
        # option_items hash must be an exclusive choice)
        check_option_usage(option_items, options, includes_uuid, false)
        # add properties passed in from command line to the json_data
        # hash that we'll be passing in as the body of the request
        body_hash = {}
        body_hash["name"] = options[:name] if options[:name]
        body_hash["tag"] = options[:tag] if options[:tag]
        json_data = body_hash.to_json
        # setup the PUT (to update the indicated tag rule) and return the results
        uri = URI.parse(@uri_string + '/' + tagrule_uuid)
        result = hnl_http_put_json_data(uri, json_data)
        print_object_array(hash_array_to_obj_array([result]), "Tag Rule Updated:")
      end

      def remove_all_tagrules
        @command = :remove_all_tagrules
        raise ProjectHanlon::Error::Slice::MethodNotAllowed, "This method has been deprecated"
      end

      def remove_tagrule_by_uuid
        @command = :remove_tagrule_by_uuid
        # the UUID was the last "previous argument"
        tagrule_uuid = @prev_args.peek(0)
        # setup the DELETE (to remove the indicated tag rule) and return the results
        uri = URI.parse @uri_string + "/#{tagrule_uuid}"
        result = hnl_http_delete(uri)
        puts result
      end

      # Tag Matcher
      #

      def get_matchers_for_tagrule
        @command = :get_matchers_for_tagrule
        tagrule_uuid = @prev_args.peek(1)
        # setup the proper URI depending on the options passed in
        uri = URI.parse(@uri_string + "/#{tagrule_uuid}/matcher")
        # get the tag matchers for the indicated tagrule (from the RESTful API) as an array of objects
        result = hnl_http_get(uri)
        unless result.blank?
          # convert it to a sorted array of objects (from an array of hashes)
          sort_fieldname = 'key'
          result = tag_matcher_hash_array_to_obj_array(expand_response_with_uris(result), tagrule_uuid, sort_fieldname)
        end
        # and print the result
        print_object_array(result, "Tag Matchers:", :style => :table)
      end

      def get_matcher_by_uuid
        @command = :get_matcher_by_uuid
        tagrule_uuid = @prev_args.peek(2)
        matcher_uuid = @prev_args.peek(0)
        # setup the proper URI depending on the options passed in
        uri = URI.parse(@uri_string + "/#{tagrule_uuid}/matcher/#{matcher_uuid}")
        # and get the results of the appropriate RESTful request using that URI
        result = hnl_http_get(uri)
        # finally, based on the options selected, print the results
        print_object_array(tag_matcher_hash_array_to_obj_array([result], tagrule_uuid), "Tag Matcher:")
      end

      def add_matcher
        @command = :add_matcher
        includes_uuid = false
        tagrule_uuid = @prev_args.peek(2)
        # load the appropriate option items for the subcommand we are handling
        option_items = command_option_data(:add_matcher)
        # parse and validate the options that were passed in as part of this
        # subcommand (this method will return a UUID value, if present, and the
        # options map constructed from the @commmand_array)
        tmp, options = parse_and_validate_options(option_items, :require_all, :banner => "hanlon tag matcher add (options...)")
        includes_uuid if tmp && tmp != "add"
        # check for usage errors (the boolean value at the end of this method
        # call is used to indicate whether the choice of options from the
        # option_items hash must be an exclusive choice)
        check_option_usage(option_items, options, includes_uuid, false)
        key = options[:key]
        compare = options[:compare]
        value = options[:value]
        inverse = (options[:inverse] == nil ? "false" : options[:inverse])
        # setup the POST (to create the requested policy) and return the results
        uri = URI.parse @uri_string + "/#{tagrule_uuid}/matcher"
        json_data = {
            "key" => key,
            "compare" => compare,
            "value" => value,
            "inverse" => inverse
        }.to_json
        result = hnl_http_post_json_data(uri, json_data)
        print_object_array(tag_matcher_hash_array_to_obj_array([result], tagrule_uuid), "Tag Matcher Added:")
      end

      def update_matcher
        @command = :update_matcher
        includes_uuid = false
        tagrule_uuid = @prev_args.peek(3)
        # load the appropriate option items for the subcommand we are handling
        option_items = command_option_data(:update_matcher)
        # parse and validate the options that were passed in as part of this
        # subcommand (this method will return a UUID value, if present, and the
        # options map constructed from the @commmand_array)
        matcher_uuid, options = parse_and_validate_options(option_items, :require_one, :banner => "hanlon policy update UUID (options...)")
        includes_uuid = true if matcher_uuid
        # check for usage errors (the boolean value at the end of this method
        # call is used to indicate whether the choice of options from the
        # option_items hash must be an exclusive choice)
        check_option_usage(option_items, options, includes_uuid, false)
        #tagrule_uuid = options[:tag_rule_uuid]
        key = options[:key]
        compare = options[:compare]
        value = options[:value]
        inverse = options[:inverse]
        # setup the PUT (to create the requested policy) and return the results
        uri = URI.parse @uri_string + "/#{tagrule_uuid}/matcher/#{matcher_uuid}"
        # add properties passed in from command line to the json_data
        # hash that we'll be passing in as the body of the request
        body_hash = {}
        body_hash["key"] = key if key
        body_hash["compare"] = compare if compare
        body_hash["value"] = value if value
        body_hash["inverse"] = inverse if inverse
        json_data = body_hash.to_json
        result = hnl_http_put_json_data(uri, json_data)
        print_object_array(tag_matcher_hash_array_to_obj_array([result], tagrule_uuid), "Tag Matcher Updated:")
      end

      def remove_matcher
        @command = :remove_matcher
        tagrule_uuid = @prev_args.peek(3)
        # the UUID was the last "previous argument"
        matcher_uuid = @prev_args.peek(0)
        # setup the DELETE (to remove the indicated model) and return the results
        uri = URI.parse @uri_string + "/#{tagrule_uuid}/matcher/#{matcher_uuid}"
        result = hnl_http_delete(uri)
        puts result
      end

    end
  end
end

