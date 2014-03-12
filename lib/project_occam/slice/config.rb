require "json"
require "yaml"

# Root ProjectOccam namespace
module ProjectOccam
  class Slice

    # ProjectOccam Slice Config
    # Used to retrieve the current Occam configuration and the
    # defined iPXE-boot script for the Occam server
    class Config < ProjectOccam::Slice

      # Initializes ProjectOccam::Slice::Model including #slice_commands, #slice_commands_help
      # @param [Array] args
      def initialize(args)
        super(args)
        @hidden = true
        @engine = ProjectOccam::Engine.instance
        @uri_string = ProjectOccam.config.mk_uri + OCCAM_URI_ROOT + '/config'
      end

      def slice_commands
        # Here we create a hash of the command string to the method it
        # corresponds to for routing.
        { :read    => "read_config",
          :dbcheck => "db_check",
          :ipxe    => "generate_ipxe_script",
          :default => :read,
          :else    => :read }
      end

      def db_check
        raise ProjectOccam::Error::Slice::MethodNotAllowed, "This method cannot be invoked via REST" if @web_command
        puts get_data.persist_ctrl.is_connected?
      end

      def read_config
        uri = URI.parse @uri_string
        config = rz_http_get_hash_response(uri)
        puts "ProjectOccam Config:"
        config.each { |key,val|
            print "\t#{key.sub("@","")}: ".white
            print "#{val} \n".green
        }
      end

      def generate_ipxe_script
        uri = URI.parse @uri_string + '/ipxe'
        ipxe_script = rz_http_get_text(uri)
        puts ipxe_script
      end

    end
  end
end
