require 'config'
require 'config/db_migrate'
require 'utility'
require 'extenders/string'

module ProjectHanlon::DbMigration

  def self.run_command(command, args)

    command = normalize_command(command)
    #puts "migration called with #{command}"

    cmd_class = "ProjectHanlon::DbMigration::Command::" + command
#puts "cmd_class is #{cmd_class}"
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

    ProjectHanlon::DbMigration::Global.args = args
    cmd.cmd_validate
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