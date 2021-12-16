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

      def view_path!(dir, name)
        filename = view_path(dir, name)

        raise "Could not find view file: #{filename}. You need to create it." unless File.exist?(filename)

        filename
      end

      def view_path(dir, name)
        File.join(@_views_path || '.', 'views', dir, "#{name}.erb")
      end

      def template(dir, name)
        Tilt.new(view_path(dir, name), engine_class: CaptureEngine, escape_html: true)
      end

      def template!(dir, name)
        Tilt.new(view_path!(dir, name), engine_class: CaptureEngine, escape_html: true)
      end

      def path(path = nil)
        @_views_path = path
      end

      def layout(name)
        @_layout = name
      end

      def render(dir, name, scope, options = {})
        t = template!(dir, name)

        layout = template('', @_layout || 'layout') unless options[:layout] != false

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
