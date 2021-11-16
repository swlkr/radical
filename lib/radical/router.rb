# typed: true
require 'rack'
require 'sorbet-runtime'

# A very naive router for radical
#
# This class loops over routes for each http method (GET, POST, etc.)
# and checks a simple regex built at startup
#
# '/users/:id' => "/users/:^#{path.gsub(/:(\w+)/, '(?<\1>[a-zA-Z0-9]+)')}$"
#
# Example:
#
# router = Router.new do
#   get '/users/:id', to: 'users#show'
# end
#
# router.route(
#   {
#     'PATH_INFO' => '/users/1',
#     'REQUEST_METHOD' => 'GET'
#   }
# ) => 'users#show(1)'
#
# Dispatches to:
#
# class UsersController < Controller
#   def show
#     render plain: "users#show(#{params['id']})"
#   end
# end
module Radical
  class Router
    extend T::Sig

    ACTIONS = [
      [:index, 'GET', ''],
      [:show, 'GET', '/:id'],
      [:new, 'GET', '/new'],
      [:create, 'POST', ''],
      [:edit, 'GET', '/:id/edit'],
      [:update, 'PUT', '/:id'],
      [:destroy, 'DELETE', '/:id']
    ].freeze

    sig { void }
    def initialize
      @routes = Hash.new { |hash, key| hash[key] = [] }
    end

    sig { params(klass: Class).void }
    def add_root(klass)
      return unless klass.method_defined?(:index)

      @routes['GET'] << [/^\/$/, [klass, 'index']]
    end

    sig { params(klass: Class).void }
    def add_routes(klass)
      prefix = klass.to_s.gsub(/([^\^])([A-Z])/,'\1_\2').downcase

      ACTIONS.each do |method, http_method, suffix|
        next unless klass.method_defined?(method)

        path = "/#{prefix}#{suffix}"
        path = Regexp.new("^#{path.gsub(/:(\w+)/, '(?<\1>[a-zA-Z0-9]+)')}$")

        @routes[http_method] << [path, [klass, method]]
      end
    end

    sig { params(request: Rack::Request).returns(Rack::Response) }
    def route(request)
      params = T.let({}, T.nilable(Hash))

      route = @routes[request.request_method].find do |r|
        params = request.path_info.match(r.first)&.named_captures
      end

      return Rack::Response.new('404 Not Found', 404) unless route

      klass, method = route.last

      # TODO: Fix this ??
      request.env['rack.input'] = ''

      params.each do |k, v|
        request.update_param(k, v)
      end

      instance = klass.new(request)

      response = instance.public_send(method)

      return response if response.is_a?(Rack::Response)

      body = instance.view(method.to_s)

      return Rack::Response.new(nil, 404) if body.nil?

      Rack::Response.new(body, 200, { 'Content-Type' => 'text/html' })
    end
  end
end
