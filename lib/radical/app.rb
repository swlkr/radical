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
# class App < Radical::App
#   root Home
# end
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
# class Controller < Radical::Controller
#   # GET /
#   def index
#     head :ok
#   end
# end
module Radical
  class App
    class << self
      def routes(route_class)
        @routes = route_class
      end

      def assets(&block)
        @assets = Assets.new

        block.call(@assets)
      end

      def compile_assets
        @assets.compile
      end

      def serve_assets
        @serve_assets = true
      end

      def security_headers(headers = {})
        @security_headers = headers
      end

      def session(options = {})
        defaults = {
          path: '/',
          secret: session_secret,
          http_only: true,
          same_site: :lax,
          secure: env.production?,
          expire_after: 2_592_000 # 30 days
        }

        @session = defaults.merge(options)
      end

      def env
        Env
      end

      def app
        router = @routes.router
        env = self.env
        assets = @assets
        serve_assets = @serve_assets
        security_headers = @security_headers || {}
        session = @session || self.session

        @app ||= Rack::Builder.app do
          use Middleware::LogfmtLogger
          use Rack::ShowExceptions if env.development?
          use Rack::Runtime
          use Rack::MethodOverride
          use Rack::ContentLength
          use Rack::ETag
          use Rack::Deflater
          use Rack::Head
          use Rack::ConditionalGet
          use Rack::ContentType
          use Rack::Session::Cookie, session
          use Rack::Csrf, raise: env.development?, skip: router.routes.values.flatten.select { |a| a.is_a?(Class) }.uniq.map(&:skip_csrf_actions).flatten(1)
          use Flash
          use SecurityHeaders, security_headers

          if serve_assets || env.development?
            use Rack::Static, urls: ['/assets', '/public'],
                              header_rules: [
                                [/\.(?:css\.gz)$/, { 'Content-Type' => 'text/css', 'Content-Encoding' => 'gzip' }],
                                [/\.(?:js\.gz)$/, { 'Content-Type' => 'application/javascript', 'Content-Encoding' => 'gzip' }],
                                [/\.(?:css\.br)$/, { 'Content-Type' => 'text/css', 'Content-Encoding' => 'br' }],
                                [/\.(?:js\.br)$/, { 'Content-Type' => 'application/javascript', 'Content-Encoding' => 'br' }]
                              ]
          end

          run lambda { |rack_env|
            begin
              router.route(Rack::Request.new(rack_env), options: { assets: assets }).finish
            rescue ModelNotFound
              raise unless env.production?

              Rack::Response.new('404 Not Found', 404).finish
            end
          }
        end
      end

      def call(env)
        app.call(env)
      end

      private

      def session_secret
        @session_secret ||= (ENV['SESSION_SECRET'] || SecureRandom.hex(32))
      end
    end
  end
end
