# frozen_string_literal: true

require_relative 'router'

module Radical
  class Routes
    class << self
      def router
        @router ||= Router.new
      end

      def root(sym)
        router.add_root(Object.const_get(sym))
      end

      def resource(sym)
        router.add_actions(Object.const_get(sym), actions: Router::RESOURCE_ACTIONS)
      end

      def resources(*symbols, &block)
        prefix = "#{router.route_prefix(@parents)}/" if instance_variable_defined?(:@parents)

        classes = symbols.map { |c| Object.const_get(c) }

        router.add_routes(classes, prefix: prefix)

        return unless block

        @parents ||= []
        @parents << classes.last
        block.call
      end
    end
  end
end
