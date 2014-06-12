# Warbler web application assembly configuration file
Warbler::Config.new do |config|
  unless RUBY_PLATFORM == 'java'
    raise 'You must build the War under JRuby or gems will not contain compatible jars.'
  end
  config.features += ['compiled','gemjar']

  config.dirs += ['api']
  config.dirs += ['conf']
  config.dirs += ['log']

  config.includes = FileList["*.rb"]

  config.jar_name = "hanlon"
end