require 'config'
require 'config/db_migrate'

module ProjectHanlon::DbMigration

  def self.run_command(command, args)
    puts "migration called with #{command}"

    cmd = CommandFactory.new
    eval "cmd.#{command}_validate args"
    eval "cmd.#{command}_exec args"
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