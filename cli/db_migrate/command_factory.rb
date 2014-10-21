require 'config'
require 'config/db_migrate'
require 'utility'
require 'extenders/string'

module ProjectHanlon::DbMigration

  def self.run_command(command, args)

    command = normalize_command(command)
    puts "migration called with #{command}"

    cmd_class = "ProjectHanlon::DbMigration::Command::" + command
puts "cmd_class is #{cmd_class}"
    cmd = ProjectHanlon::Utility.class_from_string(cmd_class).new

    #cmd = cmd_class.to_class
    # puts "finding cmd_class"
    # cmd = cmd_class.to_class
    # puts "nil class " if cmd==nil

    # puts defined?(cmd_class) == 'constant'
    # puts cmd_class.class == Class
    #
    # if defined?(cmd_class) == 'constant' && cmd_class.class == Class
    #   puts "class defined"
    # end

    #return false if cmd == nil
    #eval "cmd.#{command}_validate args"
    #eval "cmd.#{command}_exec args"

    if(cmd.cmd_validate args)
      puts "validation successful"
      return cmd.cmd_exec args
    else
      puts "validation failed"
      return false
    end
  # rescue NameError
  #   puts "Name Error"
  #   false
  end

  def self.normalize_command(command)
    command.slice(0, 1).capitalize + command.slice(1..-1).downcase
  end

  class CommandFactory
    def config_validate(args)
      puts "Configuration parameter validated"
    end

    def config_exec(args)
      puts "Configuration command executed"
      db_migrate_config = ProjectHanlon::Config::DbMigrate.new
      config = JSON(db_migrate_config.to_json)

      puts "Default Hanlon Database migration config:".yellow
      print_yaml config

      return true
    end
  end

end

module ProjectHanlon::DbMigration
  class Command

    attr_accessor :display_name, :description, :hidden

    def initialize(args = nil)
      @command_array = []
      @command_array = args if args

      @hidden = true

    end

    # Return the name of this slice - essentially, the final classname without
    # the leading hierarchy, in Ruby "filename" format rather than "classname"
    # format.  Not cached, because this is seldom used, and is never on the
    # hot path.
    def command_name
      self.class.name.
          split('::').
          last.
          scan(/[[:upper:]][[:lower:]]*/).
          join('_').
          downcase
    end
  end
end

module ProjectHanlon::DbMigration
  class CommandTemplate
    attr_accessor :command, :alt_command, :desc, :validator, :function
  end

end