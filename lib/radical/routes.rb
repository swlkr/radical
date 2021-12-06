# frozen_string_literal: true

require_relative 'router'

module Radical
  class Routes
    class << self
      def router
        @router ||= Router.new
      end

      def root(klass)
        router.add_root(klass)
      end

      def resource(klass)
        router.add_actions(klass, actions: Router::RESOURCE_ACTIONS)
      end

      def resources(*classes, &block)
        prefix = "#{router.route_prefix(@parents)}/" if instance_variable_defined?(:@parents)

        classes.map! { |c| Object.const_get(c) }

        router.add_routes(classes, prefix: prefix)

        return unless block

        @parents ||= []
        @parents << classes.last
        block.call
      end
    end
  end
end
