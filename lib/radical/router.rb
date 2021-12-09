# typed: true
# frozen_string_literal: true

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
      [:new, 'GET', '/new'],
      [:show, 'GET', '/:id'],
      [:create, 'POST', ''],
      [:edit, 'GET', '/:id/edit'],
      [:update, 'PUT', '/:id'],
      [:update, 'PATCH', '/:id'],
      [:destroy, 'DELETE', '/:id']
    ].freeze

    RESOURCE_ACTIONS = [
      [:show, 'GET', ''],
      [:edit, 'GET', '/edit'],
      [:update, 'PUT', ''],
      [:update, 'PATCH', ''],
      [:destroy, 'DELETE', '']
    ].freeze

    attr_accessor :routes

    sig { void }
    def initialize
      @routes = Hash.new { |hash, key| hash[key] = [] }
    end

    sig { params(classes: T::Array[Class]).returns(String) }
    def route_prefix(classes)
      classes.map(&:route_name).map { |n| "#{n}/:#{n}_id" }.join('/')
    end

    sig { params(klass: Class).void }
    def add_root(klass)
      add_actions(klass, name: '')
    end

    sig { params(klass: Class, name: T.nilable(String), prefix: T.nilable(String), actions: Array).void }
    def add_actions(klass, name: nil, prefix: nil, actions: ACTIONS)
      name ||= klass.route_name

      actions.each do |method, http_method, suffix|
        next unless klass.method_defined?(method)

        path = "/#{prefix}#{name}#{suffix}"
        path = Regexp.new("^#{path.gsub(/:(\w+)/, '(?<\1>[a-zA-Z0-9_]+)')}$").freeze

        if %i[index create show update destroy].include?(method) && !klass.method_defined?(:"#{klass.route_name}_path")
          klass.define_method :"#{klass.route_name}_path" do |obj = nil|
            if obj.is_a?(Model)
              "/#{klass.route_name}/#{obj.id}"
            else
              "/#{klass.route_name}"
            end
          end
        end

        if method == :new
          klass.define_method :"new_#{klass.route_name}_path" do
            "/#{klass.route_name}/new"
          end
        end

        if method == :edit
          klass.define_method :"edit_#{klass.route_name}_path" do |obj|
            "/#{klass.route_name}/#{obj.id}/edit"
          end
        end

        @routes[http_method] << [path, [klass, method]]
      end
    end

    sig { params(classes: T::Array[Class], prefix: T.nilable(String), actions: Array).void }
    def add_routes(classes, prefix: nil, actions: ACTIONS)
      classes.each do |klass|
        add_actions(klass, prefix: prefix, actions: actions)
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
