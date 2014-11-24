
module ProjectHanlon::Migrate
  class Command

    class Config < ProjectHanlon::Migrate::Command

      def initialize
        super

        @hidden = false
        @display_name = "config"
        @description = "Get / set hanlon database migration configuration parameters"

        @cmd_function = "display_config"
        @cmd_map =
            [
                ["-t", "--test", "Validate current configuration file for any issues", "no_more_args", "test_config"],
                ["-g", "--generate", "Generate a default config file", "no_more_args","generate_config"],
                ["-s**", "--show", "Generate a default config file", "no_more_args","show_config"],
                ["-h", "--help", "Display this help message", "no_more_args", "cmd_help"]
            ]
      end

      def generate_config

        #ToDo:: To be implemented

        return true
      end

      def show_config
        #ToDo:: To be implemented

        return true
      end

      def test_config
        #ToDo:: To be implemented

        return true
      end
    end
  end
end