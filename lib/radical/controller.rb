# typed: true
# frozen_string_literal: true

require 'rack/utils'
require 'rack/request'
require 'rack/response'
require 'sorbet-runtime'
require_relative 'view'
require_relative 'env'
require_relative 'form'

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

    sig { params(name: T.any(String, Symbol)).returns(String) }
    def view(name)
      View.render(self.class.route_name, name, self)
    end

    sig { params(name: T.any(String, Symbol)).returns(String) }
    def partial(name)
      View.render(self.class.route_name, "_#{name}", self, layout: false)
    end

    sig { params(options: Hash, block: T.proc.void).returns(String) }
    def form(options, &block)
      f = Form.new(options, self)

      capture(block) do
        emit f.open_tag
        emit f.csrf_tag
        emit f.rack_override_tag
        yield f
        emit f.close_tag
      end
    end

    sig { params(to: T.any(Symbol, String)).returns(Rack::Response) }
    def redirect(to)
      to = self.class.action_to_url(to) if to.is_a?(Symbol)

      Rack::Response.new(nil, 302, { 'Location' => to })
    end

    def flash
      @request.env['rack.session']['__FLASH__']
    end

    def session
      @request.env['rack.session']
    end

    private

    def emit(tag)
      @output = '' if @output.nil?
      @output << tag.to_s
    end

    def capture(block)
      @output = eval('_buf', block.binding)
      yield
      @output
    end
  end
end
