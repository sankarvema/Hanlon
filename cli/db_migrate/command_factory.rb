
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
      return true
    end
  end

end