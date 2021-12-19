# frozen_string_literal: true

require '../../lib/radical'

class Controller < Radical::Controller
  prepend_view_path '/var/app/examples/assets'
end

class HomeController < Controller
  def index; end
end

class Routes < Radical::Routes
  root :HomeController
end

class App < Radical::App
  routes Routes

  assets do |a|
    a.prepend_assets_path '/var/app/examples/assets'

    a.css %w[
      a.css
      b.css
    ]

    a.js %w[
      a.js
      b.js
    ]

    a.brotli
  end

  if Radical.env.production?
    compile_assets
    serve_assets # this is just for example, you would probably have nginx/caddy or something serve the assets in production
  end
end

run App
