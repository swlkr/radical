# typed: true
# frozen_string_literal: true

require_relative 'router'

module Radical
  class Routes
    class << self
      extend T::Sig

      sig { returns(Router) }
      def router
        @router ||= Router.new
      end

      sig { params(name: T.any(String, Symbol)).void }
      def root(name)
        klass = Object.const_get(name)

        router.add_root(klass)
      end

      sig { params(names: T.any(String, Symbol)).void }
      def resource(*names)
        classes = names.map { |c| Object.const_get(c) }

        classes.each do |klass|
          router.add_actions(klass, actions: Router::RESOURCE_ACTIONS)
        end
      end

      sig { params(names: T.any(String, Symbol), block: T.nilable(T.proc.void)).void }
      def resources(*names, &block)
        classes = names.map { |c| Object.const_get(c) }

        prefix = "#{router.route_prefix(@parents)}/" if instance_variable_defined?(:@parents)

        router.add_routes(classes, prefix: prefix)

        return unless block

        @parents ||= []
        @parents << classes.last
        block.call
      end
    end
  end
end
