# frozen_string_literal: true

require 'securerandom'
require 'rack'
require 'rack/csrf'

require_relative 'asset'
require_relative 'assets'
require_relative 'asset_compiler'
require_relative 'env'
require_relative 'flash'
require_relative 'routes'
require_relative 'security_headers'
require_relative 'middleware/logfmt_logger'

# The main entry point for a Radical application
#
# Example:
#
# App = Radical::App.new(
#   routes: Radical::Routes.new do
#     root :HomeController
#   end
# )
#
# App.call(
#   {
#     'PATH_INFO' => '/',
#     'REQUEST_METHOD' => 'GET'
#   }
# )
#
# Dispatches to:
#
# class HomeController < Radical::Controller
#   # GET /
#   def index
#     head :ok
#   end
# end
module Radical
  class App
    attr_accessor :router, :routes, :assets, :session, :security_headers
    attr_writer :serve_assets

    def initialize(routes:, assets: {}, session: {}, security_headers: {})
      @routes = routes
      @router = routes.router
      @assets = Assets.new(assets)
      @session = session_defaults.merge(session)
      @security_headers = security_headers
      @serve_assets = false
      rack_builder
    end

    def compile_assets
      @assets.compile
    end

    def serve_assets
      @serve_assets = true
    end

    def call(env)
      @app.call(env)
    end

    private

    def rack_builder
      this = self

      @app ||= Rack::Builder.new do
        use Radical::Middleware::LogfmtLogger
        use Rack::ShowExceptions if Radical.env.development?
        use Rack::Runtime
        use Rack::MethodOverride
        use Rack::ContentLength
        use Rack::ETag
        use Rack::Deflater
        use Rack::Head
        use Rack::ConditionalGet
        use Rack::ContentType
        use Rack::Session::Cookie, this.session
        use Rack::Csrf, raise: Radical.env.development?, skip: this.router.routes.values.flatten.select { |a| a.is_a?(Radical::Controller) }.uniq.map(&:skip_csrf_actions).flatten(1)
        use Radical::Flash
        use Radical::SecurityHeaders, this.security_headers

        if this.serve_assets || Radical.env.development?
          use Rack::Static, urls: ['/assets', '/public'],
                            header_rules: [
                              [/\.(?:css\.gz)$/, { 'Content-Type' => 'text/css', 'Content-Encoding' => 'gzip' }],
                              [/\.(?:js\.gz)$/, { 'Content-Type' => 'application/javascript', 'Content-Encoding' => 'gzip' }],
                              [/\.(?:css\.br)$/, { 'Content-Type' => 'text/css', 'Content-Encoding' => 'br' }],
                              [/\.(?:js\.br)$/, { 'Content-Type' => 'application/javascript', 'Content-Encoding' => 'br' }]
                            ]
        end

        run lambda { |env|
          begin
            this.router.route(Rack::Request.new(env), options: { assets: this.assets }).finish
          rescue ModelNotFound, RouteNotFound, NotFound
            raise unless Radical.env.production?

            not_found_page = File.read File.join(Dir.pwd, 'public', '404.html')

            Rack::Response.new(not_found_page, 404, { 'Content-Type' => 'text/html' }).finish
          rescue StandardError
            raise unless Radical.env.production?

            server_error_page = File.read File.join(Dir.pwd, 'public', '500.html')

            Rack::Response.new(server_error_page, 500, { 'Content-Type' => 'text/html' }).finish
          end
        }
      end
    end

    def session_defaults
      {
        path: '/',
        secret: session_secret,
        http_only: true,
        same_site: :lax,
        secure: Radical.env.production?,
        expire_after: 2_592_000 # 30 days
      }
    end

    def session_secret
      @session_secret ||= (ENV['SESSION_SECRET'] || SecureRandom.hex(32))
    end
  end
end
