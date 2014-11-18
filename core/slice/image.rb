require "json"
require "yaml"
require "image_service/base"

# Root ProjectHanlon namespace
module ProjectHanlon
  class Slice

    # TODO - add inspection to prevent duplicate MK's with identical version to be added

    # ProjectHanlon Slice Image
    # Used for image management
    class Image < ProjectHanlon::Slice

      attr_reader :image_types

      # Initializes ProjectHanlon::Slice::Model including #slice_commands, #slice_commands_help
      # @param [Array] args
      def initialize(args)
        super(args)
        @hidden = false
        @uri_string = ProjectHanlon.config.hanlon_uri + ProjectHanlon.config.websvc_root + '/image'
        # get the available image types (input type must match one of these)
        @image_types = {
            :mk =>       {
                :desc => "MicroKernel ISO",
                :classname => "ProjectHanlon::ImageService::MicroKernel",
                :method => "add_mk"
            },
            :os =>        {
                :desc => "OS Install ISO",
                :classname => "ProjectHanlon::ImageService::OSInstall",
                :method => "add_os"
            },
            :esxi =>      {
                :desc => "VMware Hypervisor ISO",
                :classname => "ProjectHanlon::ImageService::VMwareHypervisor",
                :method => "add_esxi"
            },
            :xenserver => {
                :desc => "XenServer Hypervisor ISO",
                :classname => "ProjectHanlon::ImageService::XenServerHypervisor",
                :method => "add_xenserver"
            }
        }
      end

      def self.additional_fields
        %w"@local_image_path @status @status_message"
      end

      def slice_commands
        # get the slice commands map for this slice (based on the set
        # of commands that are typical for most slices)
        get_command_map(
            "image_help",
            "get_images",
            "get_image_by_uuid",
            "add_image",
            nil,
            nil,
            "remove_image")
      end

      def all_command_option_data
        {
            :add => [
                { :name        => :type,
                  :default     => nil,
                  :short_form  => '-t',
                  :long_form   => '--type TYPE',
                  :description => 'The type of image (mk, os, esxi, or xenserver)',
                  :uuid_is     => 'not_allowed',
                  :required    => true
                },
                { :name        => :path,
                  :default     => nil,
                  :short_form  => '-p',
                  :long_form   => '--path /path/to/iso',
                  :description => 'The local path to the image ISO',
                  :uuid_is     => 'not_allowed',
                  :required    => true
                },
                { :name        => :name,
                  :default     => nil,
                  :short_form  => '-n',
                  :long_form   => '--name IMAGE_NAME',
                  :description => 'The logical name to use (os images only)',
                  :uuid_is     => 'not_allowed',
                  :required    => false
                },
                { :name        => :version,
                  :default     => nil,
                  :short_form  => '-v',
                  :long_form   => '--version VERSION',
                  :description => 'The version to use (os images only)',
                  :uuid_is     => 'not_allowed',
                  :required    => false
                }
            ]
        }.freeze
      end

      def image_help
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
        puts "Image Slice: used to add, view, and remove Images.".red
        puts "Image Commands:".yellow
        puts "\thanlon image [get] [all]         " + "View all images (detailed list)".yellow
        puts "\thanlon image [get] (UUID)        " + "View details of specified image".yellow
        puts "\thanlon image add (options...)    " + "Add a new image to the system".yellow
        puts "\thanlon image remove (UUID)       " + "Remove existing image from the system".yellow
        puts "\thanlon image --help|-h           " + "Display this screen".yellow
      end

      #Lists details for all images
      def get_images
        @command = :get_images
        # get the images from the RESTful API (as an array of objects)
        uri = URI.parse @uri_string
        result = hnl_http_get(uri)
        unless result.blank?
          # convert it to a sorted array of objects (from an array of hashes)
          sort_fieldname = 'filename'
          result = hash_array_to_obj_array(expand_response_with_uris(result), sort_fieldname)
        end
        # and print the result
        print_object_array(result, "Images:", :style => :table)
      end

      #Lists details for a specific image
      def get_image_by_uuid
        @command = :get_image_by_uuid
        image_uuid = get_uuid_from_prev_args
        # setup the proper URI depending on the options passed in
        uri = URI.parse(@uri_string + '/' + image_uuid)
        # and get the results of the appropriate RESTful request using that URI
        result = hnl_http_get(uri)
        # finally, based on the options selected, print the results
        print_object_array(hash_array_to_obj_array([result]), "Image:")
      end

      #Add an image
      def add_image
        @command = :add_image
        includes_uuid = false
        # load the appropriate option items for the subcommand we are handling
        option_items = command_option_data(:add)
        # parse and validate the options that were passed in as part of this
        # subcommand (this method will return a UUID value, if present, and the
        # options map constructed from the @commmand_array)
        tmp, options = parse_and_validate_options(option_items, :require_all, :banner => "hanlon image add (options...)")
        includes_uuid = true if tmp && tmp != "add"
        # check for usage errors (the boolean value at the end of this method
        # call is used to indicate whether the choice of options from the
        # option_items hash must be an exclusive choice)
        check_option_usage(option_items, options, includes_uuid, false)
        image_type = options[:type]
        # Note; the following expression will expand the path that is passed in into an
        # absolute directory in the case where a relative path (with respect to the current
        # working directory) was passed in.  If the user passed in an absolute path to the file,
        # then this expression will leave that absolute path unchanged
        iso_path = File.expand_path(options[:path], Dir.pwd)
        os_name = options[:name]
        os_version = options[:version]

        # setup the POST (to create the requested policy) and return the results
        uri = URI.parse @uri_string

        body_hash = {
            "type" => image_type,
            "path" => iso_path
        }
        body_hash["name"] = os_name if os_name
        body_hash["version"] = os_version if os_version
        json_data = body_hash.to_json
        puts "Attempting to add, please wait...".green
        result = hnl_http_post_json_data(uri, json_data)
        print_object_array(hash_array_to_obj_array([result]), "Image Added:")
      end

      def remove_image
        @command = :remove_image
        # the UUID is the first element of the @command_array
        image_uuid = get_uuid_from_prev_args
        # setup the DELETE (to remove the indicated image) and return the results
        uri = URI.parse @uri_string + "/#{image_uuid}"
        result = hnl_http_delete(uri)
        slice_success(result, :success_type => :removed)
      end

      # utility methods (used to add various types of images)

      def add_mk(new_image, iso_path, image_path)
        new_image.add(iso_path, image_path, nil)
      end

      def add_esxi(new_image, iso_path, image_path)
        new_image.add(iso_path, image_path, nil)
      end

      def add_xenserver(new_image, iso_path, image_path)
        new_image.add(iso_path, image_path, nil)
      end

      def add_os(new_image, iso_path, image_path, os_name, os_version)
        raise ProjectHanlon::Error::Slice::MissingArgument,
              'image name must be included for OS images' unless os_name && os_name != ""
        raise ProjectHanlon::Error::Slice::MissingArgument,
              'image version must be included for OS images' unless os_version && os_version != ""
        new_image.add(iso_path, image_path, {:os_version => os_version, :os_name => os_name})
      end

      def insert_image(image_obj)
        image_obj = @data.persist_object(image_obj)
        image_obj.refresh_self
      end

    end
  end
end
