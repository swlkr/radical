require 'rack/request'

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
# app = App.new
# app.call(
#   {
#     'PATH_INFO' => '/',
#     'REQUEST_METHOD' => 'GET'
#   }
# )
#
# Dispatches to:
#
# module Home
#   class Controller < Radical::Controller
#     # GET /
#     def index
#       head :ok
#     end
#   end
# end
module Radical
  class App
    class << self
      attr_accessor :router

      def root(klass)
        @router ||= Router.new
        @router.add_root(klass)
      end

      def routes(klass)
        @router ||= Router.new
        @router.add_routes(klass)
      end

      def env
        Env
      end
    end

    def call(rack_env)
      return Rack::Response.new(nil, 404).finish if self.class.router.nil?

      request = Rack::Request.new(rack_env)
      response = self.class.router.route(request)

      response.finish
    end
  end
end
