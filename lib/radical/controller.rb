# typed: true
require 'rack/utils'
require 'rack/request'
require 'rack/response'
require 'sorbet-runtime'
require_relative 'view'
require_relative 'env'

module Radical
  class Controller
    extend T::Sig

    attr_accessor :request

    class << self
      extend T::Sig

      attr_accessor :skip_csrf_actions

      sig { params(path: String).void }
      def prepend_view_path(path)
        View.path path
      end

      def layout(name)
        View.layout name
      end

      sig { returns(String) }
      def route_name
        to_s.split('::').last.gsub(/Controller$/, '').gsub(/([A-Z])/, '_\1')[1..-1].downcase
      end

      sig { params(actions: Symbol).void }
      def skip_csrf(*actions)
        @skip_csrf_actions = [] if @skip_csrf_actions.nil?

        actions.each do |action|
          @skip_csrf_actions << "#{action_to_http_method(action)}:#{action_to_url(action)}"
        end
      end

      sig { params(action: Symbol).returns(String) }
      def action_to_url(action)
        case action
        when :index, :create
          "/#{route_name}"
        when :show, :update, :destroy
          "/#{route_name}/:id"
        when :new
          "/#{route_name}/new"
        when :edit
          "/#{route_name}/:id/edit"
        end
      end

      sig { params(action: Symbol).returns(String) }
      def action_to_http_method(action)
        case action
        when :index, :show, :new, :edit
          'GET'
        when :create
          'POST'
        when :update
          'PATCH'
        when :destroy
          'DELETE'
        end
      end
    end

    sig { params(request: Rack::Request).void }
    def initialize(request)
      @request = request
    end

    sig { params(status: T.any(Symbol, Integer)).returns(Rack::Response) }
    def head(status)
      Rack::Response.new(nil, Rack::Utils::SYMBOL_TO_STATUS_CODE[status])
    end

    sig { params(body: String).returns(Rack::Response) }
    def plain(body)
      Rack::Response.new(body, 200, { 'Content-Type' => 'text/plain' })
    end

    sig { returns(Hash) }
    def params
      @request.params
    end

    sig { params(name: String).returns(String) }
    def view(name)
      dir = self.class.to_s.gsub(/([A-Z])/, '_\1')[1..-1].downcase

      View.render(dir, name, binding)
    end

    sig { params(path: String).void }
    def self.prepend_view_path(path)
      Radical::View.path path
    end
  end
end
