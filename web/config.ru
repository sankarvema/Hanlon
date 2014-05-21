require './application'

use Rack::Static,
    :urls => ["/images", "/js", "/css"],
    :root => "public",
    :index => "index.html",
    :header_rules => [
      [:all, {'Cache-Control' => 'public, max-age=86400'}]
    ]

run Hanlon::WebService::App.new
