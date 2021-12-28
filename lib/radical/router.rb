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

    sig { params(classes: T::Array[T.class_of(Controller)]).returns(String) }
    def route_prefix(classes)
      classes.map(&:route_name).map { |n| "#{n}/:#{n}_id" }.join('/')
    end

    sig { params(klass: T.class_of(Controller)).void }
    def add_root(klass)
      add_routes(klass, name: '', actions: ACTIONS)
      add_root_paths(klass)
    end

    sig { params(klass: T.class_of(Controller)).void }
    def add_resource(klass)
      add_routes(klass, actions: RESOURCE_ACTIONS)
      add_resource_paths(klass)
    end

    sig { params(klass: T.class_of(Controller), parents: T.nilable(T::Array[T.class_of(Controller)])).void }
    def add_resources(klass, parents: nil)
      if parents
        parents.each do |scope|
          add_routes(klass, actions: ACTIONS, scope: scope)
          add_resources_paths(klass, scope: scope)
          add_resources_urls(klass, scope: scope)
        end
      else
        add_routes(klass, actions: ACTIONS)
        add_resources_paths(klass)
        add_resources_urls(klass)
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

    sig { params(klass: T.class_of(Controller), scope: T.nilable(T.class_of(Controller))).void }
    def add_resources_urls(klass, scope: nil)
      route_name = klass.route_name
      scope_name = [scope&.route_name, klass.route_name].compact.join('_')

      if %i[index create show update destroy].any? { |method| klass.method_defined?(method) }
        if scope
          Controller.define_method :"#{scope_name}_url" do |parent = nil|
            [url_prefix, scope.route_name, parent&.id, route_name].join('/')
          end
        end

        Controller.define_method :"#{route_name}_url" do |obj = nil|
          [url_prefix, route_name, obj&.id].compact.join('/')
        end
      end

      if klass.method_defined?(:new)
        Controller.define_method :"new_#{scope_name || route_name}_url" do |parent = nil|
          [url_prefix, scope&.route_name, parent&.id, route_name, 'new'].compact.join('/')
        end
      end

      return unless klass.method_defined?(:edit)

      Controller.define_method :"edit_#{route_name}_url" do |obj|
        [url_prefix, route_name, obj.id, 'edit'].join('/')
      end
    end

    sig { params(klass: T.class_of(Controller)).void }
    def add_root_paths(klass)
      route_name = klass.route_name

      if %i[index create show update destroy].any? { |method| klass.method_defined?(method) }
        Controller.define_method :"#{route_name}_path" do |obj = nil|
          if obj
            "/#{obj.id}"
          else
            '/'
          end
        end
      end

      if klass.method_defined?(:new)
        Controller.define_method :"new_#{route_name}_path" do
          '/new'
        end
      end

      return unless klass.method_defined?(:edit)

      Controller.define_method :"edit_#{route_name}_path" do |obj|
        "/#{obj.id}/edit"
      end
    end

    sig { params(klass: T.class_of(Controller)).void }
    def add_resource_paths(klass)
      name = klass.route_name

      if %i[create show update destroy].any? { |method| klass.method_defined?(method) }
        Controller.define_method :"#{name}_path" do
          "/#{name}"
        end
      end

      if klass.method_defined?(:new)
        Controller.define_method :"new_#{name}_path" do
          "/#{name}/new"
        end
      end

      return unless klass.method_defined?(:edit)

      Controller.define_method :"edit_#{name}_path" do
        "/#{name}/edit"
      end
    end

    sig { params(klass: T.class_of(Controller), scope: T.nilable(T.class_of(Controller))).void }
    def add_resources_paths(klass, scope: nil)
      route_name = klass.route_name
      scope_path_name = [scope&.route_name, route_name].compact.join('_')

      if %i[index create show update destroy].any? { |method| klass.method_defined?(method) }
        if scope
          Controller.define_method :"#{scope_path_name}_path" do |parent, params = {}|
            path_ = ['', scope.route_name, parent.id, route_name].compact.join('/')
            path_ += "?#{Rack::Utils.build_nested_query(params)}" unless params.empty?

            path_
          end
        end

        Controller.define_method :"#{route_name}_path" do |obj = nil, params = {}|
          path_ = ['', route_name, obj&.id].compact.join('/')
          path_ += "?#{Rack::Utils.build_nested_query(params)}" unless params.empty?

          path_
        end
      end

      if klass.method_defined?(:new)
        if scope
          Controller.define_method :"new_#{scope_path_name}_path" do |parent, params = {}|
            path = ['', scope.route_name, parent.id, route_name, 'new'].join('/')
            path += "?#{Rack::Utils.build_nested_query(params)}" unless params.empty?

            path
          end
        else
          Controller.define_method :"new_#{route_name}_path" do |params = {}|
            path = ['', route_name, 'new'].join('/')
            path += "?#{Rack::Utils.build_nested_query(params)}" unless params.empty?

            path
          end
        end
      end

      return unless klass.method_defined?(:edit)

      Controller.define_method :"edit_#{route_name}_path" do |obj, params = {}|
        path = ['', route_name, obj.id, 'edit'].join('/')
        path += "?#{Rack::Utils.build_nested_query(params)}" unless params.empty?

        path
      end
    end
  end
end
