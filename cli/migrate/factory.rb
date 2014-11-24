module ProjectHanlon::Migrate

  def self.run_command(command, args)

    command = normalize_command(command)
    puts "migration called with #{command}"

    cmd_class = "ProjectHanlon::Migrate::Command::" + command
    puts "cmd_class is #{cmd_class}"
    cmd = class_from_string(cmd_class).new

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
    # rescue NameError
    #   puts "Name Error"
    #   false
  end

  def self.normalize_command(command)
    command.slice(0, 1).capitalize + command.slice(1..-1).downcase
  end

  def self.class_from_string(str)
    str.split('::').inject(Object) do |mod, class_name|
      mod.const_get(class_name)
    end
  end
end