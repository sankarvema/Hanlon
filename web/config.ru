require './application'

use Rack::Static,
    :urls => ["/images", "/js", "/css"],
    :root => "public"


run Hanlon::WebService::App.new
