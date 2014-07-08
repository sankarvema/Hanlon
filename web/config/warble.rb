# Override init.rb file creation logic
#class Warbler::Jar
#  alias_method :orig_add_init_file, :add_init_file

#  def add_init_file(config)
#    config.gem_path = '/WEB-INF/lib/gems.jar'
#    orig_add_init_file(config)
#  end
#end

# Warbler web application assembly configuration file
Warbler::Config.new do |config|
  unless RUBY_PLATFORM == 'java'
    raise 'You must build the War under JRuby or gems will not contain compatible jars.'
  end
  config.features += ['gemjar']

  #config.gem_path = '/WEB-INF/lib/gems.jar'
  config.init_contents =  %w(config/init.rb)
  config.dirs += ['api']
  config.dirs += ['conf']
  config.dirs += ['log']

  config.includes = FileList["*.rb"]

  config.jar_name = "hanlon"
end