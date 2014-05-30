#require 'project_hanlon'

require 'json'
require 'colored'
require 'optparse'
require 'slice'
require 'logging/logger'
require 'slice/config'

class ProjectHanlon::CLI
  include(ProjectHanlon::Logging)
  # We set a constant for our Slice root Namespace. We use this to pull the
  # slice names back out from objectspace
  SLICE_PREFIX = "ProjectHanlon::Slice::"

  # Create a new instance of the CLI dispatcher, ready to service requests.
  def initialize
    @obj = ProjectHanlon::Object.new
    @logger = @obj.get_logger

  end

  # Run a single invocation of a command line from Hanlon; this translates the
  # command line into a slice invocation, parsing options along the way, and
  # eventually reports back the result.
  #
  # @param [Array<String>] the command line arguments
  # @return [Boolean] true on success, false on failure
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

    slice = argv.shift
    if call_hanlon_slice(slice, argv)
      return true
    end

    puts optparse
    print_available_slices
    if slice
      print "\n [#{slice}] ".red
      print "<-Invalid Slice \n".yellow
    end
    return false
  end

  private

  def call_hanlon_slice(raw_name, args)
    return nil if raw_name.nil?

    if raw_name == 'config' and @web_command and !@cli_private then
      @logger.error "Hanlon config called as web command"
      return false # Will yield 404 which is good. This slice doesn't exist in the web UI
    end

    name = file2const(raw_name)
    hanlon_module = Object.full_const_get(SLICE_PREFIX + name).new(args)
    hanlon_module.web_command = @web_command
    hanlon_module.verbose = @verbose
    hanlon_module.debug = @debug
    hanlon_module.slice_call
    return true
  rescue => e
    unless e.to_s =~ /uninitialized constant ProjectHanlon::Slice::/
      @logger.error "Hanlon slice error: #{e.message}"
      logger.error "Hanlon slice error occured: #{e.message}"
      logger.log_exception(e)

      print "\n [#{raw_name}] ".red
      print "<- #{e.message} \n".yellow
    end
    raise e if @debug
    return false
  end

  def print_available_slices
    print "\n", "Available slices\n\t".yellow
    x = 1
    # first, find all slices that extend the ProjectHanlon::Slice class
    slices = ObjectSpace.each_object(Class).select { |klass| klass < ProjectHanlon::Slice }
    # then construct a hash containing those slices (or slice classes); the key for
    # this hash is the slice name
    slices_hash = Hash[slices.map { |a| [a.new([]).slice_name, a] }]
    # finally, output the list of slice names (sorted by name) for all
    # of the "non-hidden" slices
    slices_hash.keys.sort.each do |slice_name|
      slice_obj = slices_hash[slice_name].new([])
      unless slice_obj.hidden
        print "[#{slice_name}] ".white
        if x > 5
          print "\n\t"
          x = 0
        end
        x += 1
      end
    end
    print "\n"
  end

  def get_optparse
    OptionParser.new do |opts|
      opts.version   = ProjectHanlon::VERSION
      opts.banner    = "#{opts.program_name} - #{opts.version}".green
      opts.separator "Usage: ".yellow
      opts.separator "    hanlon [slice name] [command argument] [command argument]...".red
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

      #@options[:jsoncommand] = false
      #opts.on( '-j', '--jsoncommand', 'Same as -w but not exposed in web UI.'.yellow ) do
      #  @options[:jsoncommand] = true
      #end

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
        print_available_slices
        exit
      end
    end
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

  # Translate a filename-style constant string into a Ruby-style
  # constant string.  That is, maps `foo_bar` into `FooBar`.
  #
  # @param filename [String] the file-system style name.
  # @return [String] the Ruby style name.
  def file2const(filename)
    filename.to_s.split('_').map(&:capitalize).join
  end

  # Translate a Ruby-style constant string into a file-system style
  # name string.  That is, maps `FooBar` to `foo_bar`.
  #
  # @param const [String] the Ruby style name.
  # @return [String] the file-system style string.
  def const2file(const)
    const.to_s.split(/(?=[A-Z])/).map(&:downcase).join('_')
  end
end
