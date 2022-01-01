# frozen_string_literal: true

require '../../lib/radical'

class Controller < Radical::Controller
  prepend_view_path '/var/app/examples/assets'
end

class HomeController < Controller
  def index; end
end

routes = Radical::Routes.new do
  root :HomeController
end

app = Radical::App.new(
  routes: routes

  assets: {
    prepend_assets_path: '/var/app/examples/assets',

    css: %w[
      a.css
      b.css
    ]

    js: %w[
      a.js
      b.js
    ]

    brotli: true
  }
)

if Radical.env.production?
  app.compile_assets
  app.serve_assets # this is just for example, you would probably have nginx/caddy or something serve the assets in production
end

run app
