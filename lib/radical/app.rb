# frozen_string_literal: true

require 'securerandom'
require 'rack'
require 'rack/flash'
require 'rack/csrf'

require_relative 'routes'
require_relative 'env'

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
        @routes ||= route_class
      end

      def env
        Env
      end

      def app
        router = @routes.router
        env = self.env
        session_secret = self.session_secret

        @app ||= Rack::Builder.app do
          use Rack::CommonLogger
          use Rack::ShowExceptions if env.development?
          use Rack::Runtime
          use Rack::MethodOverride
          use Rack::ContentLength
          use Rack::Deflater
          use Rack::ETag
          use Rack::Head
          use Rack::ConditionalGet
          use Rack::ContentType
          use Rack::Session::Cookie, path: '/',
                                     secret: session_secret,
                                     http_only: true,
                                     same_site: :lax,
                                     secure: env.production?,
                                     expire_after: 2_592_000 # 30 days
          use Rack::Csrf, raise: env.development?, skip: router.routes.values.flatten.select { |a| a.is_a?(Class) }.uniq.map(&:skip_csrf_actions).flatten(1)
          use Rack::Flash, sweep: true

          run lambda { |rack_env|
            begin
              router.route(Rack::Request.new(rack_env)).finish
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
