
# Warbler web application assembly configuration file
Warbler::Config.new do |config|
  unless RUBY_PLATFORM == 'java'
    raise 'You must build the War under JRuby or gems will not contain compatible jars.'
  end
  config.features += ['compiled','gemjar']
  config.dirs += ['api']
  config.jar_name = "razor"
end