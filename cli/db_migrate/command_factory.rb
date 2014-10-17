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

    def print_yaml(data)
      data.each { |key,val|
        print "\t#{key.sub("@","")}: ".white
        print "#{val} ".green
        print "\n"
      }
    end
  end

end