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
#     plain "users#show(#{params['id']})"
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
      [:new, 'GET', '/new'],
      [:create, 'POST', ''],
      [:show, 'GET', ''],
      [:edit, 'GET', '/edit'],
      [:update, 'PUT', ''],
      [:update, 'PATCH', ''],
      [:destroy, 'DELETE', '']
    ].freeze

    SUFFIX_ACTIONS = %i[edit new].freeze

    attr_accessor :routes

    sig { void }
    def initialize
      @routes = Hash.new { |hash, key| hash[key] = [] }
    end

    sig { params(klass: T.class_of(Controller), parents: T.nilable(T::Array[T.class_of(Controller)])).void }
    def add_root(klass, parents: nil)
      if parents
        parents.each do |scope|
          add_routes(klass, name: '', actions: ACTIONS, scope: scope)
          add_root_paths(klass, scope: scope)
          add_root_paths(klass, scope: scope, url: true)
        end
      else
        add_routes(klass, name: '', actions: ACTIONS)
        add_root_paths(klass)
        add_root_paths(klass, url: true)
      end
    end

    sig { params(klass: T.class_of(Controller), parents: T.nilable(T::Array[T.class_of(Controller)])).void }
    def add_resource(klass, parents: nil)
      if parents
        parents.each do |scope|
          add_routes(klass, actions: RESOURCE_ACTIONS, scope: scope)
          add_resource_paths(klass, scope: scope)
          add_resource_paths(klass, scope: scope, url: true)
        end
      else
        add_routes(klass, actions: RESOURCE_ACTIONS)
        add_resource_paths(klass)
        add_resource_paths(klass, url: true)
      end
    end

    sig { params(klass: T.class_of(Controller), parents: T.nilable(T::Array[T.class_of(Controller)])).void }
    def add_resources(klass, parents: nil)
      if parents
        parents.each do |scope|
          add_routes(klass, actions: ACTIONS, scope: scope)
          add_resources_paths(klass, scope: scope)
          add_resources_paths(klass, scope: scope, url: true)
        end
      else
        add_routes(klass, actions: ACTIONS)
        add_resources_paths(klass)
        add_resources_paths(klass, url: true)
      end
    end

    sig { params(request: Rack::Request, options: T.nilable(Hash)).returns(Rack::Response) }
    def route(request, options: {})
      params = T.let({}, T.nilable(Hash))

      route = @routes[request.request_method].find do |r|
        params = request.path_info.match(r.first)&.named_captures
      end

      return Rack::Response.new('404 Not Found', 404) unless route

      klass, method = route.last

      params&.each do |k, v|
        request.update_param(k, v)
      end

      instance = klass.new(request, options: options)

      response = instance.public_send(method)

      return response if response.is_a?(Rack::Response)

      body = instance.view(method.to_s)

      return Rack::Response.new(nil, 404) if body.nil?

      Rack::Response.new(body, 200, { 'Content-Type' => 'text/html' })
    end

    private

    sig { params(klass: T.class_of(Controller), actions: Array, name: T.nilable(String), scope: T.nilable(T.class_of(Controller))).void }
    def add_routes(klass, actions:, name: nil, scope: nil)
      name ||= klass.route_name

      actions.each do |method, http_method, suffix|
        next unless klass.method_defined?(method)

        path = if scope
                 if %i[index new create].include?(method)
                   "/#{scope.route_name}/:#{scope.route_name}_id/#{name}#{suffix}"
                 else
                   "/#{name}#{suffix}"
                 end
               else
                 "/#{name}#{suffix}"
               end

        path = Regexp.new("^#{path.gsub(/:(\w+)/, '(?<\1>[a-zA-Z0-9_]+)')}$").freeze

        @routes[http_method] << [path, [klass, method]]
      end
    end

    sig { params(klass: T.class_of(Controller), scope: T.nilable(T.class_of(Controller)), url: T::Boolean).void }
    def add_root_paths(klass, scope: nil, url: false)
      ACTIONS.each do |action, _, _|
        method = :"#{[action, scope&.route_name, klass.route_name, url ? 'url' : 'path'].compact.join('_')}"

        next if !klass.method_defined?(action) || Controller.method_defined?(method)

        Controller.define_method method do |model = nil, params = {}|
          route_path(
            action: action,
            route_name: '',
            model: model,
            params: params,
            scope: scope,
            prefix: url ? url_prefix : ''
          )
        end
      end
    end

    sig { params(klass: T.class_of(Controller), scope: T.nilable(T.class_of(Controller)), url: T::Boolean).void }
    def add_resource_paths(klass, scope: nil, url: false)
      RESOURCE_ACTIONS.each do |action, _, _|
        method = :"#{[action, scope&.route_name, klass.route_name, url ? 'url' : 'path'].compact.join('_')}"

        next if !klass.method_defined?(action) || Controller.method_defined?(method)

        Controller.define_method method do |params = {}|
          route_path(
            action: action,
            route_name: klass.route_name,
            scope: scope,
            params: params,
            prefix: url ? url_prefix : ''
          )
        end
      end
    end

    sig { params(klass: T.class_of(Controller), scope: T.nilable(T.class_of(Controller)), url: T::Boolean).void }
    def add_resources_paths(klass, scope: nil, url: false)
      ACTIONS.each do |action, _, _|
        method = :"#{[action, scope&.route_name, klass.route_name, url ? 'url' : 'path'].compact.join('_')}"

        next if !klass.method_defined?(action) || Controller.method_defined?(method)

        Controller.define_method method do |model = nil, params = {}|
          route_path(
            action: action,
            model: model,
            route_name: klass.route_name,
            scope: scope,
            params: params,
            prefix: url ? url_prefix : ''
          )
        end
      end
    end
  end
end
