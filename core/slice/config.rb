require "json"
require "yaml"

# Root ProjectHanlon namespace
module ProjectHanlon
  class Slice

    # ProjectHanlon Slice Config
    # Used to retrieve the current Hanlon configuration and the
    # defined iPXE-boot script for the Hanlon server
    class Config < ProjectHanlon::Slice

      # Initializes ProjectHanlon::Slice::Model including #slice_commands, #slice_commands_help
      # @param [Array] args
      def initialize(args)
        super(args)
        @hidden = true
        #@engine = ProjectHanlon::Engine.instance
        @uri_string = ProjectHanlon.config.hanlon_uri + ProjectHanlon.config.websvc_root + '/config'
      end

      def slice_commands
        # get the slice commands map for this slice (start with a
        # template that is based on the set of commands that are
        # typical for most slices)
        commands = get_command_map(
            "config_help",
            "read_config",
            nil,
            nil,
            nil,
            nil,
            nil)
        # then add a couple of additional methods (that are
        # specific to this slice)
        commands[:db_check] = "db_check"
        commands[:ipxe] = "generate_ipxe_script"
        commands
      end

      def config_help
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
        puts "Config Slice: used to view/check config.".red
        puts "Config Commands:".yellow
        puts "\thanlon config [get]      " + "View the current Hanlon configuration".yellow
        puts "\thanlon config db_check   " + "Check the Hanlon database connection".yellow
        puts "\thanlon config ipxe       " + "Generate an iPXE script (for use with TFTP)".yellow
      end

      def db_check
        @command = :db_check
        raise ProjectHanlon::Error::Slice::MethodNotAllowed, "This method cannot be invoked via REST" if @web_command
        puts get_data.persist_ctrl.is_connected?
      end

      def read_config
        @command = :read_config
        uri = URI.parse @uri_string
        # and get the results of the appropriate RESTful request using that URI
        include_http_response = true
        result, response = hnl_http_get(uri, include_http_response)
        if response.instance_of?(Net::HTTPBadRequest)
          raise ProjectHanlon::Error::Slice::CommandFailed, result["result"]["description"]
        end
        puts "ProjectHanlon Config:"
        result.each { |key,val|
            print "\t#{key.sub("@","")}: ".white
            print "#{val} ".green
            print "\n"
        }
      end

      def generate_ipxe_script
        @command = :generate_ipxe_script
        uri = URI.parse @uri_string + '/ipxe'
        # and get the results of the appropriate RESTful request using that URI
        include_http_response = true
        result, response = hnl_http_get(uri, include_http_response)
        if response.instance_of?(Net::HTTPBadRequest)
          raise ProjectHanlon::Error::Slice::CommandFailed, result["result"]["description"]
        end
        puts result
      end

    end
  end
end
