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
      [:new, 'GET', '/new'],
      [:create, 'POST', ''],
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
      add_routes(klass, name: '', actions: RESOURCE_ACTIONS)
      add_root_paths(klass)
    end

    sig { params(klass: Class).void }
    def add_resource(klass)
      add_routes(klass, actions: RESOURCE_ACTIONS)
      add_resource_paths(klass)
    end

    sig { params(klass: Class, parents: T.nilable(T::Array[Class])).void }
    def add_resources(klass, parents: nil)
      if parents
        parents.each do |scope|
          add_routes(klass, actions: ACTIONS, scope: scope)
          add_resources_paths(klass, scope: scope)
        end
      else
        add_routes(klass, actions: ACTIONS)
        add_resources_paths(klass)
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

      params.each do |k, v|
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

    sig { params(klass: Class, actions: Array, name: T.nilable(String), scope: T.nilable(Class)).void }
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

    sig { params(klass: Class).void }
    def add_root_paths(klass)
      route_name = klass.route_name

      if %i[index create show update destroy].any? { |method| klass.method_defined?(method) }
        klass.define_method :"#{route_name}_path" do |obj = nil|
          if obj
            "/#{obj.id}"
          else
            '/'
          end
        end
      end

      if klass.method_defined?(:new)
        klass.defined_method :"new_#{route_name}_path" do
          '/new'
        end
      end

      return unless klass.method_defined?(:edit)

      klass.defined_method :"edit_#{route_name}_path" do |obj|
        "/#{obj.id}/edit"
      end
    end

    sig { params(klass: Class).void }
    def add_resource_paths(klass)
      name = klass.route_name

      if %i[create show update destroy].any? { |method| klass.method_defined?(method) }
        klass.define_method :"#{name}_path" do
          "/#{name}"
        end
      end

      if klass.method_defined?(:new)
        klass.define_method :"new_#{name}_path" do
          "/#{name}/new"
        end
      end

      return unless klass.method_defined?(:edit)

      klass.define_method :"edit_#{name}_path" do
        "/#{name}/edit"
      end
    end

    sig { params(klass: Class, scope: T.nilable(Class)).void }
    def add_resources_paths(klass, scope: nil)
      path_name = klass.route_name
      scope_path_name = [scope&.route_name, klass.route_name].compact.join('_')
      name = klass.route_name

      if %i[index create show update destroy].any? { |method| klass.method_defined?(method) }
        if scope
          klass.define_method :"#{scope_path_name}_path" do |parent|
            "/#{scope.route_name}/#{parent.id}/#{name}"
          end

          klass.define_method :"#{path_name}_path" do |obj|
            "/#{name}/#{obj.id}"
          end
        else
          klass.define_method :"#{path_name}_path" do |obj = nil|
            if obj
              "/#{name}/#{obj.id}"
            else
              "/#{name}"
            end
          end
        end
      end

      if klass.method_defined?(:new)
        if scope
          klass.define_method :"new_#{scope_path_name}_path" do |parent|
            "/#{scope.route_name}/#{parent.id}/#{name}/new"
          end
        else
          klass.define_method :"new_#{path_name}_path" do
            "/#{name}/new"
          end
        end
      end

      return unless klass.method_defined?(:edit)

      klass.define_method :"edit_#{path_name}_path" do |obj|
        "/#{name}/#{obj.id}/edit"
      end
    end
  end
end
