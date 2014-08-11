require './application'
require 'yaml'

hanlon_config = YAML::load(File.open('config/hanlon_server.conf'))

use Rack::Static,
    :urls => ["/images", "/js", "/css"],
    :root => "public",
    :index => "index.html",
    :header_rules => [
      [:all, {'Cache-Control' => 'public, max-age=86400'}]
    ]

# test to see if starting up as a WAR file or not
is_warbler = Module.const_defined?(:WARBLER_CONFIG)

if is_warbler
  run Hanlon::WebService::App.new
else
  run Rack::URLMap.new(
      hanlon_config['base_path'] => Hanlon::WebService::App.new
  )
end