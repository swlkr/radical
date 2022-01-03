# frozen_string_literal: true

require 'rack/csrf'
require_relative 'tag'

module Radical
  class Form
    def initialize(options, controller)
      @options = options
      @model = options[:model]
      @controller = controller
      @override_method = options[:method]&.upcase || (@model&.saved? ? 'PATCH' : 'POST')
      @method = %w[GET POST].include?(@override_method) ? @override_method : 'POST'
      @action = options[:action] || options[:url] || action_from(model: @model, controller: controller)
      @tag = Tag.new
    end

    def text(name, attrs = {})
      attrs.merge!(type: 'text', name: name, value: @model&.public_send(name))

      @tag.input attrs
    end

    def hidden(name, attrs = {})
      attrs.merge!(type: 'hidden', name: name, value: @model&.public_send(name))

      @tag.input attrs
    end

    def number(name, attrs = {})
      attrs.merge!(type: 'number', name: name, value: @model&.public_send(name))

      @tag.input attrs
    end

    def button(attrs = {}, &block)
      @tag.string 'button', attrs, &block
    end

    def submit(value_or_attrs = {})
      attrs = {}

      case value_or_attrs
      when String
        attrs[:value] = value_or_attrs
      when Hash
        attrs = value_or_attrs || {}
      end

      @tag.string 'input', attrs.merge('type' => 'submit')
    end

    def open_tag
      attrs = @options.slice(:class, :style).merge(action: @action, method: @method)

      @tag.open_tag('form', attrs)
    end

    def csrf_tag
      Rack::Csrf.tag(@controller.request.env)
    end

    def rack_override_tag
      attrs = { value: @override_method, type: 'hidden', name: '_method' }

      @tag.input(attrs) unless %w[GET POST].include?(@override_method)
    end

    def close_tag
      @tag.close_tag('form')
    end

    private

    def action_from(controller:, model:)
      return if model.nil?

      path_name = model.class.table_name

      if model.saved?
        controller.send(:"update_#{path_name}_path", model)
      else
        controller.send(:"create_#{path_name}_path", model)
      end
    end
  end
end
