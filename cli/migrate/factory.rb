module ProjectHanlon::Migrate

  def self.run_command(command, args)

    command = normalize_command(command)
    begin
      cmd_class = "ProjectHanlon::Migrate::Command::" + command
      cmd = ProjectHanlon::Utility.class_from_string(cmd_class).new

      #ToDo:: Throws exception on wrong command

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

      ProjectHanlon::Migrate::Global.args = args
      cmd.cmd_validate
    rescue NameError
      false
    end
  end

  def self.normalize_command(command)
    command.slice(0, 1).capitalize + command.slice(1..-1).downcase
  end

end