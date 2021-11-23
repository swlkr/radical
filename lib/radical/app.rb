require 'rack/request'
require 'rack/builder'

require_relative 'router'
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
    @app = nil

    class << self
      def root(klass)
        router.add_root(klass)
      end

      def resource(klass)
        router.add_routes(klass, actions: Router::PREFIX_ACTIONS)
      end

      def resources(klass)
        router.add_routes(klass)
      end

      def env
        Env
      end

      def app
        router = self.router
        env = self.env

        @app ||= Rack::Builder.app do
          use Rack::CommonLogger
          use Rack::ShowExceptions if env.development?
          use Rack::MethodOverride
          use Rack::ContentLength
          use Rack::Deflater
          use Rack::ETag
          use Rack::Head
          use Rack::ContentType

          run lambda { |rack_env| router.route(Rack::Request.new(rack_env)).finish }
        end
      end

      def router
        @router ||= Router.new
      end

      def call(env)
        app.call(env)
      end
    end
  end
end
