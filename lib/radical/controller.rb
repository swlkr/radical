# typed: true
# frozen_string_literal: true

require 'rack/utils'
require 'rack/request'
require 'rack/response'
require 'sorbet-runtime'
require_relative 'view'
require_relative 'env'
require_relative 'form'
require_relative 'strings'

module Radical
  class Controller
    extend T::Sig

    attr_accessor :request

    class << self
      extend T::Sig

      attr_accessor :skip_csrf_actions, :_layout

      sig { params(path: String).void }
      def prepend_view_path(path)
        View.path path
      end

      def layout(name)
        @_layout = name
      end

      sig { returns(String) }
      def route_name
        Strings.snake_case to_s.split('::').last&.gsub(/Controller$/, '')
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
        else
          ''
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
        else
          ''
        end
      end
    end

    attr_reader :options

    sig { params(request: Rack::Request, options: T.nilable(Hash)).void }
    def initialize(request, options: {})
      @request = request
      @options = options
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

    sig { params(name: T.any(String, Symbol), locals: T.nilable(Hash)).returns(String) }
    def view(name, locals = {})
      View.render(name, self, { locals: locals, layout: self.class._layout })
    end

    sig { params(name: T.any(String, Symbol), locals: T.nilable(Hash)).returns(String) }
    def partial(name, locals = {})
      View.partial(name, self, { locals: locals, layout: false })
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

    def redirect_location(val)
      case val
      when Model
        send("show_#{val.table_name}_path", val)
      when Symbol
        send("#{val}_#{self.class.route_name}_path")
      when String
        val
      else
        ''
      end
    end

    sig { params(to: T.any(Model, Symbol, String), options: Hash).returns(Rack::Response) }
    def redirect(to, options = {})
      options.each { |k, v| flash[k] = v }
      location = redirect_location to

      Rack::Response.new(nil, 302, { 'Location' => location })
    end

    def flash
      @request.env['rack.session']['__FLASH__']
    end

    def session
      @request.env['rack.session']
    end

    def assets_path(type)
      assets = options[:assets]

      if Env.production?
        compiled_assets_path(assets, type)
      else
        not_compiled_assets_path(assets, type)
      end
    end

    def url_prefix
      port = @request.port == 80 || @request.port == 443 ? '' : ":#{@request.port}"

      "#{@request.scheme}://#{@request.host}#{port}"
    end

    def route_path(action:, route_name:, model: nil, scope: nil, params: {}, prefix: '')
      query_string = "?#{Rack::Utils.build_nested_query(params)}" unless params.empty?
      suffix = action if Router::SUFFIX_ACTIONS.include?(action)

      path = if scope
               [prefix, scope.route_name, model&.id, route_name, suffix].compact.join('/')
             else
               [prefix, route_name, model&.id, suffix].compact.join('/')
             end

      [path, query_string].compact.join('')
    end

    private

    def compiled_assets_path(assets, type)
      if type == :css
        link_tag(assets.compiled[:css])
      else
        script_tag(assets.compiled[:js])
      end
    end

    def not_compiled_assets_path(assets, type)
      if type == :css
        assets.assets[:css].map do |asset|
          link_tag("/assets/#{type}/#{asset}")
        end.join("\n")
      else
        assets.assets[:js].map do |asset|
          script_tag("/assets/#{type}/#{asset}")
        end.join("\n")
      end
    end

    def emit(tag)
      @output = String.new if @output.nil?
      @output << tag.to_s
    end

    def capture(block)
      @output = eval '_buf', block.binding
      yield
      @output
    end

    def script_tag(src)
      "<script type=\"application/javascript\" src=\"#{src}\"></script>"
    end

    def link_tag(href)
      "<link rel=\"stylesheet\" type=\"text/css\" href=\"#{href}\" />"
    end
  end
end
