# frozen_string_literal: true

require 'rack/csrf'

module Radical
  class Form
    def initialize(options, controller)
      @model = options[:model]
      @controller = controller
      @route_name = @controller.class.route_name
      @override_method = options[:method]&.upcase || (@model.saved? ? 'PATCH' : 'POST')
      @method = %w[GET POST].include?(@override_method) ? @override_method : 'POST'

      @action = if @model.saved?
                  @controller.public_send(:"#{@route_name}_path", @model)
                else
                  @controller.public_send(:"#{@route_name}_path")
                end
    end

    def text(name)
      "<input type=text name=#{@route_name}[#{name}] value=\"#{@model.public_send(name)}\" />"
    end

    def button(name)
      "<button type=submit>#{name}</button>"
    end

    def submit(value)
      "<input type=submit value=#{value} />"
    end

    def open_tag
      "<form action=#{@action} method=#{@method}>"
    end

    def csrf_tag
      Rack::Csrf.tag(@controller.request.env)
    end

    def rack_override_tag
      "<input type=hidden name=_method value=#{@override_method} />" unless %w[GET POST].include?(@override_method)
    end

    def close_tag
      '</form>'
    end
  end
end
