# frozen_string_literal: true

require 'rack/csrf'

module Radical
  class Form
    SELF_CLOSING_TAGS = %w[
      area
      base
      br
      col
      embed
      hr
      img
      input
      keygen
      link
      meta
      param
      source
      track
      wbr
    ].freeze

    def initialize(options, controller)
      @model = options[:model]
      @controller = controller
      @route_name = @controller.class.route_name
      @override_method = options[:method]&.upcase || (@model&.saved? ? 'PATCH' : 'POST')
      @method = %w[GET POST].include?(@override_method) ? @override_method : 'POST'

      @action = if @model&.saved?
                  @controller.public_send(:"#{@route_name}_path", @model)
                elsif @model && !@model.saved?
                  @controller.public_send(:"#{@route_name}_path")
                else
                  options[:action] || 'POST'
                end
    end

    def text(name, attrs = {})
      attrs.merge!(type: 'text', name: "#{@route_name}[#{name}]", value: @model&.public_send(name))

      tag 'input', attrs
    end

    def number(name, attrs = {})
      attrs.merge!(type: 'number', name: "#{@route_name}[#{name}]", value: @model&.public_send(name))

      tag 'input', attrs
    end

    def button(attrs = {}, &block)
      tag 'button', attrs, &block
    end

    def submit(value_or_attrs = {})
      attrs = {}

      case value_or_attrs
      when String
        attrs[:value] = value_or_attrs
      when Hash
        attrs = value_or_attrs || {}
      end

      tag 'input', attrs.merge('type' => 'submit')
    end

    def open_tag
      "<form #{html_attributes(action: @action, method: @method)}>"
    end

    def csrf_tag
      Rack::Csrf.tag(@controller.request.env)
    end

    def rack_override_tag
      attrs = { value: @override_method, type: 'hidden', name: '_method' }

      tag('input', attrs) unless %w[GET POST].include?(@override_method)
    end

    def close_tag
      '</form>'
    end

    private

    def tag(name, attrs, &block)
      attr_string = attrs.empty? ? '' : " #{html_attributes(attrs)}"
      open_tag = "<#{name}"
      self_closing = SELF_CLOSING_TAGS.include?(name)
      end_tag = self_closing ? ' />' : "</#{name}>"

      "#{open_tag}#{attr_string}#{self_closing ? '' : '>'}#{block&.call}#{end_tag}"
    end

    def html_attributes(options = {})
      options.transform_keys(&:to_s).sort_by { |k, _| k }.map { |k, v| "#{k}=\"#{v}\"" }.join(' ')
    end
  end
end
