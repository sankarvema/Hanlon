require 'json'
require 'project_hanlon/model/base'

# Root ProjectHanlon namespace
module ProjectHanlon
  class Slice

    # ProjectHanlon Slice Model
    class Model < ProjectHanlon::Slice

      # Root namespace for model objects; used to find them
      # in object space in order to gather meta-data for creating models
      SLICE_MODEL_PREFIX = "ProjectHanlon::ModelTemplate::"

      # Initializes ProjectHanlon::Slice::Model including #slice_commands, #slice_commands_help
      # @param [Array] args
      def initialize(args)
        super(args)
        @hidden = false
        @uri_string = ProjectHanlon.config.hanlon_uri + ProjectHanlon.config.websvc_root + '/model'
      end

      def slice_commands
        # get the slice commands map for this slice (based on the set
        # of commands that are typical for most slices)
        commands = get_command_map(
            "model_help",
            "get_all_models",
            "get_model_by_uuid",
            "add_model",
            "update_model",
            "remove_all_models",
            "remove_model_by_uuid")
        # and add any additional commands specific to this slice
        commands[:get].delete(/^(?!^(all|\-\-help|\-h|\{\}|\{.*\}|nil)$)\S+$/)
        commands[:get][:else] = "get_model_by_uuid"
        commands[:get][[/^(temp|template|templates|types)$/]] = "get_all_templates"

        commands
      end

      def all_command_option_data
        {
            :add => [
                { :name        => :template,
                  :default     => false,
                  :short_form  => '-t',
                  :long_form   => '--template MODEL_TEMPLATE',
                  :description => 'The model template to use for the new model.',
                  :uuid_is     => 'not_allowed',
                  :required    => true
                },
                { :name        => :label,
                  :default     => false,
                  :short_form  => '-l',
                  :long_form   => '--label MODEL_LABEL',
                  :description => 'The label to use for the new model.',
                  :uuid_is     => 'not_allowed',
                  :required    => true
                },
                { :name        => :image_uuid,
                  :default     => false,
                  :short_form  => '-i',
                  :long_form   => '--image-uuid IMAGE_UUID',
                  :description => 'The image UUID to use for the new model.',
                  :uuid_is     => 'not_allowed',
                  :required    => true
                }
            ],
            :update => [
                { :name        => :label,
                  :default     => false,
                  :short_form  => '-l',
                  :long_form   => '--label MODEL_LABEL',
                  :description => 'The new label to use for the model.',
                  :uuid_is     => 'required',
                  :required    => true
                },
                { :name        => :image_uuid,
                  :default     => false,
                  :short_form  => '-i',
                  :long_form   => '--image-uuid IMAGE_UUID',
                  :description => 'The new image UUID to use for the model.',
                  :uuid_is     => 'required',
                  :required    => true
                },
                { :name        => :change_metadata,
                  :default     => false,
                  :short_form  => '-c',
                  :long_form   => '--change-metadata',
                  :description => 'Used to trigger a change in the model\'s meta-data',
                  :uuid_is     => 'required',
                  :required    => true
                }
            ]
        }.freeze
      end

      def model_help
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
        puts get_model_help
      end

      def get_model_help
        return ["Model Slice: used to add, view, update, and remove models.".red,
                "Model Commands:".yellow,
                "\thanlon model [get] [all]                 " + "View all models".yellow,
                "\thanlon model [get] (UUID)                " + "View specific model instance".yellow,
                "\thanlon model [get] template|templates    " + "View list of model templates".yellow,
                "\thanlon model add (options...)            " + "Create a new model instance".yellow,
                "\thanlon model update (UUID) (options...)  " + "Update a specific model instance".yellow,
                "\thanlon model remove (UUID)|all           " + "Remove existing model(s)".yellow,
                "\thanlon model --help                      " + "Display this screen".yellow].join("\n")
      end

      def get_all_models
        @command = :get_all_models
        uri = URI.parse @uri_string
        model_array = hash_array_to_obj_array(expand_response_with_uris(rz_http_get(uri)))
        print_object_array(model_array, "Models:", :style => :table)
      end

      def get_model_by_uuid
        @command = :get_model_by_uuid
        # the UUID is the first element of the @command_array
        model_uuid = @command_array.first
        # setup the proper URI depending on the options passed in
        uri = URI.parse(@uri_string + '/' + model_uuid)
        # and get the results of the appropriate RESTful request using that URI
        include_http_response = true
        result, response = rz_http_get(uri, include_http_response)
        if response.instance_of?(Net::HTTPBadRequest)
          raise ProjectHanlon::Error::Slice::CommandFailed, result["result"]["description"]
        end
        # finally, based on the options selected, print the results
        print_object_array(hash_array_to_obj_array([result]), "Model:")
      end

      def get_all_templates
        @command = :get_all_templates
        # get the list of model templates nd print it
        uri = URI.parse @uri_string + '/templates'
        model_templates = hash_array_to_obj_array(expand_response_with_uris(rz_http_get(uri)))
        print_object_array(model_templates, "Model Templates:")
      end

      def add_model
        @command = :add_model
        includes_uuid = false
        # load the appropriate option items for the subcommand we are handling
        option_items = command_option_data(:add)
        # parse and validate the options that were passed in as part of this
        # subcommand (this method will return a UUID value, if present, and the
        # options map constructed from the @commmand_array)
        tmp, options = parse_and_validate_options(option_items, "hanlon model add (options...)", :require_all)
        includes_uuid = true if tmp && tmp != "add"
        # check for usage errors (the boolean value at the end of this method
        # call is used to indicate whether the choice of options from the
        # option_items hash must be an exclusive choice)
        check_option_usage(option_items, options, includes_uuid, false)
        template = options[:template]
        label = options[:label]
        image_uuid = options[:image_uuid]
        # use the arguments passed in to create a new model
        model = get_model_using_template_name(options[:template])
        model.cli_create_metadata
        # setup the POST (to create the requested policy) and return the results
        uri = URI.parse @uri_string
        body_hash = {
            "template" => template,
            "label" => label,
            "image_uuid" => image_uuid,
            "req_metadata_hash" => model.req_metadata_hash
        }
        model.req_metadata_hash.each { |key, md_hash_value|
          value = model.instance_variable_get(key)
          body_hash[key] = value
        }
        json_data = body_hash.to_json
        result, response = rz_http_post_json_data(uri, json_data, true)
        if response.instance_of?(Net::HTTPBadRequest)
          raise ProjectHanlon::Error::Slice::CommandFailed, result["result"]["description"]
        end
        print_object_array(hash_array_to_obj_array([result]), "Model Created:")
      end

      def update_model
        @command = :update_model
        includes_uuid = false
        # load the appropriate option items for the subcommand we are handling
        option_items = command_option_data(:update)
        # parse and validate the options that were passed in as part of this
        # subcommand (this method will return a UUID value, if present, and the
        # options map constructed from the @commmand_array)
        model_uuid, options = parse_and_validate_options(option_items, "hanlon model update UUID (options...)", :require_one)
        includes_uuid = true if model_uuid
        # check for usage errors (the boolean value at the end of this method
        # call is used to indicate whether the choice of options from the
        # option_items hash must be an exclusive choice)
        check_option_usage(option_items, options, includes_uuid, false)
        label = options[:label]
        image_uuid = options[:image_uuid]
        change_metadata = options[:change_metadata]
        # now, use the values that were passed in to update the indicated model
        uri = URI.parse(@uri_string + '/' + model_uuid)
        # and get the results of the appropriate RESTful request using that URI
        include_http_response = true
        result, response = rz_http_get(uri, include_http_response)
        if response.instance_of?(Net::HTTPBadRequest)
          raise ProjectHanlon::Error::Slice::CommandFailed, result["result"]["description"]
        end
        model = hash_to_obj(result)
        # if the user requested a change to the meta-data hash associated with the
        # indicated model, then gather that new meta-data from the user
        if change_metadata
          raise ProjectHanlon::Error::Slice::UserCancelled, "User cancelled Model creation" unless
              model.cli_create_metadata
        end
        # add properties passed in from command line to the json_data
        # hash that we'll be passing in as the body of the request
        body_hash = {}
        body_hash["label"] = label if label
        body_hash["image_uuid"] = image_uuid if image_uuid
        if change_metadata
          model.req_metadata_hash.each { |key, md_hash_value|
            value = model.instance_variable_get(key)
            body_hash[key] = value
          }
          body_hash["req_metadata_hash"] = model.req_metadata_hash
        end
        json_data = body_hash.to_json
        # setup the PUT (to update the indicated policy) and return the results
        result, response = rz_http_put_json_data(uri, json_data, true)
        if response.instance_of?(Net::HTTPBadRequest)
          raise ProjectHanlon::Error::Slice::CommandFailed, result["result"]["description"]
        end
        print_object_array(hash_array_to_obj_array([result]), "Model Updated:")
      end

      def remove_all_models
        @command = :remove_all_models
        raise ProjectHanlon::Error::Slice::MethodNotAllowed, "This method has been deprecated"
      end

      def remove_model_by_uuid
        @command = :remove_model_by_uuid
        # the UUID was the last "previous argument"
        model_uuid = get_uuid_from_prev_args
        # setup the DELETE (to remove the indicated model) and return the results
        uri = URI.parse @uri_string + "/#{model_uuid}"
        result, response = rz_http_delete(uri, true)
        if response.instance_of?(Net::HTTPBadRequest)
          raise ProjectHanlon::Error::Slice::CommandFailed, result["result"]["description"]
        end
        slice_success(result, :success_type => :removed)
      end

      def verify_image(model, image_uuid)
        uri = URI.parse ProjectHanlon.config.hanlon_uri + ProjectHanlon.config.websvc_root + "/image/#{image_uuid}"
        # and get the results of the appropriate RESTful request using that URI
        include_http_response = true
        result, response = rz_http_get(uri, include_http_response)
        if response.instance_of?(Net::HTTPBadRequest)
          raise ProjectHanlon::Error::Slice::CommandFailed, result["result"]["description"]
        end
        # finally, based on the options selected, print the results
        image = hash_to_obj(result)
        if image && (image.class != Array || image.length > 0)
          return image if model.image_prefix == image.path_prefix
        end
        nil
      end

      def get_model_using_template_name(template_name)
        get_child_types(SLICE_MODEL_PREFIX).each { |template|
          return template if template.name.to_s == template_name
        }
        nil
      end

    end
  end
end
