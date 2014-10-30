
module ProjectHanlon::DbMigration
  class Command

    class Config < ProjectHanlon::DbMigration::Command

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

        puts "Creating hanlon migrate configuration file...".cyan

        puts "#{$config_file_path} ? #{File.exist?( $config_file_path)}"

        cli_config_path = $config_file_path
        client_config = ProjectHanlon::Config::DbMigrate.new

        case check_file client_config, cli_config_path
          when -1
            puts "   existing migrate config file at #{cli_config_path} left intact"
          when 0
            puts "   a new default migrate configuration created at #{cli_config_path}"
          when 1
            puts "   a new default migrate configuration created at #{cli_config_path}"
            puts "   existing file backed up with timestamp"
        end

        puts
        puts "Please edit respective configuration files as needed before starting #{ProjectHanlon::Properties.app_name} migrate"

        return true
      end

      def show_config
        puts "Configuration command executed"
        db_migrate_config = ProjectHanlon::Config::DbMigrate.new
        config = JSON(db_migrate_config.to_json)

        puts "Default Hanlon Database migration config:".yellow
        ProjectHanlon::Utility.print_yaml config

        return true
      end

      def check_file(obj, web_config_path)
        file_action = 0 # 0 -create new 1 - overwrite existing 2 - skip

        if File.exist? web_config_path then
          puts "   existing config file found at #{web_config_path}"

          begin
            printf "   Do you want to replace it? [y/N] "
            input = STDIN.gets.strip.upcase

            if input == ''
              input =  'N'
            end

            if ! %w(Y N).include? input
              puts "   sorry, invalid response!!!".red
            end

          end while ! %w(Y N).include? input

          if %w(Y).include? input then
            File.rename web_config_path, web_config_path + "_" + Time.now.strftime("%m%d%Y%I%M") + ".bak"
            file_action = 1
          else
            return file_action = -1
          end


        end
        obj.save_as_yaml(web_config_path)
        return file_action

      end

      def test_config
        puts "Test current configuration parameters...".blue
        puts
        puts "Current parameters...".yellow
        config = ProjectHanlon::Config::Common.instance
        config_yaml = JSON(config.to_json)
        ProjectHanlon::Utility.print_yaml config_yaml
        puts

        source_connection = Mongo::Connection.new(config.source_persist_host, config.source_persist_port)
        dist_connection = Mongo::Connection.new(config.destination_persist_host, config.destination_persist_port)
        source_db= source_connection.db(config.source_persist_dbname)
        dest_db= dist_connection.db(config.destination_persist_dbname)

        puts "Check parameters...".yellow
        puts "\tSource database connection:: #{source_connection.active? ? 'OK':'Failed'}"
        puts "\tDestination database connection:: #{dist_connection.active? ? 'OK':'Failed'}"

        return true
      end
    end
  end
end