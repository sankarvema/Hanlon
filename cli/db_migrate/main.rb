require 'json'
require 'colored'
require 'optparse'
require 'hanlon_global'
require 'logging/logger'
require 'slice/config'
require 'properties'
require 'db_migrate/global'


class ProjectHanlon::Main
  include(ProjectHanlon::Logging)

  def run(*argv)

    first_args = get_first_args(argv)
    first_args.size.times {argv.shift}
    @options = {}
    optparse = get_optparse

    begin
      optparse.parse(first_args)
    rescue OptionParser::InvalidOption => e
      # We may use this option later so we will continue
      #puts e.message
      #puts optparse
      #exit
    end

    @cli_private = false

    #if @options[:jsoncommand] then
    #  @web_command = true
    #  @cli_private = true
    #end

    @debug = @options[:debug]
    @verbose = @options[:verbose]

    if @options[:nocolor] or !STDOUT.tty?
      # if this flag is set, override the default behavior of the underlying
      # "colorize" method from the "Colored" module so that it just returns
      # the string that was passed into it (this will have the effect of
      # turning off any color that might be included in any of the output
      # statements involving Strings in Hanlon)
      ::Colored.module_eval do
        def colorize(string, options = {})
          string
        end
      end
      String.send("include", Colored)
      optparse = get_optparse # reload optparse with color disabled
    end

    command = argv.shift
    if ProjectHanlon::DbMigration::run_command(command, argv)
      return ProjectHanlon::DbMigration::ErrorCodes[:no_error]
    end

    puts optparse
    print_available_commands
    if command
      print "\n [#{command}] ".red
      print "<-Invalid Command \n".yellow
    end
    return ProjectHanlon::DbMigration::ErrorCodes[:invalid_arguments]

  end

  def get_first_args(argv)
    f = []
    argv.each do |a|
      if a.start_with?("-")
        f << a
      else
        return f
      end
    end
    f
  end

  def get_optparse
    OptionParser.new do |opts|
      opts.version   = ProjectHanlon::VERSION
      opts.banner    = "#{opts.program_name} - #{opts.version}".green
      opts.separator "Usage: ".yellow
      opts.separator "    hanlon_migrate [command] [command argument] [command argument]...".red
      opts.separator ""
      opts.separator "Switches".yellow

      @options[:verbose] = false
      opts.on( '-v', '--verbose', 'Enables verbose object printing'.yellow ) do
        @options[:verbose] = true
      end

      @options[:debug] = false
      opts.on( '-d', '--debug', 'Enables printing proper Ruby stacktrace'.yellow ) do
        @options[:debug] = true
      end

      @options[:nocolor] = false
      opts.on( '-n', '--no-color', 'Disables console color. Useful for script wrapping.'.yellow ) do
        @options[:nocolor] = true
      end

      opts.on_tail('-V', '--version', 'Display the version of Hanlon'.yellow) do
        puts opts.banner
        exit
      end

      opts.on_tail( '-h', '--help', 'Display this screen'.yellow ) do
        print opts
        #print_available_slices
        exit
      end
    end
  end

  def print_banner
    puts
    puts "#{ProjectHanlon::Properties.app_name} (ver #{ProjectHanlon::Properties.app_build_version})".green
    puts ProjectHanlon::Properties.app_copy_right.yellow
    puts
  end

  def print_available_commands
    puts "Available commands"
  end
end