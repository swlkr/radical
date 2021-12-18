# frozen_string_literal: true

require 'erubi'
require 'tilt'

module Radical
  class CaptureEngine < ::Erubi::Engine
    private

    BLOCK_EXPR = /\s*((\s+|\))do|\{)(\s*\|[^|]*\|)?\s*\Z/.freeze

    def add_expression(indicator, code)
      if BLOCK_EXPR.match?(code) && %w[== =].include?(indicator)
        src << ' ' << code
      else
        super
      end
    end
  end

  class View
    class << self
      attr_accessor :_views_path, :_layout

      def view_path(name, controller = nil)
        parts = name.split(File::SEPARATOR)
        parts.unshift(controller.class.route_name) if parts.one? && controller

        "#{File.join(@_views_path || '.', 'views', *parts)}.erb"
      end

      def template(filename)
        Tilt.new(filename, engine_class: CaptureEngine, escape_html: true)
      end

      def path(path = nil)
        @_views_path = path
      end

      def layout(name)
        @_layout = name
      end

      def partial(name, scope, options = {})
        render(name, scope, options.merge(layout: false))
      end

      def render(name, scope, options = {})
        filename = view_path(name, scope)

        raise "Could not find view file: #{filename}. You need to create it." unless File.exist?(filename)

        t = template(filename)

        layout_path = view_path(options[:layout] || @_layout || 'layout')

        layout = template(layout_path) if options[:layout] != false && File.exist?(layout_path)

        if layout
          layout.render scope, {} do
            t.render scope, options[:locals] || {}
          end
        else
          t.render scope
        end
      end
    end
  end
end
