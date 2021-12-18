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

      def parents
        @parents ||= []
      end

      sig { params(name: T.any(String, Symbol)).void }
      def root(name)
        klass = Object.const_get name

        router.add_root klass
      end

      sig { params(names: T.any(String, Symbol)).void }
      def resource(*names)
        names.each do |name|
          klass = Object.const_get name
          router.add_resource klass
        end
      end

      sig { params(names: T.any(String, Symbol), block: T.nilable(T.proc.void)).void }
      def resources(*names, &block)
        names.each do |name|
          klass = Object.const_get name

          if parents.any?
            router.add_resources(klass, parents: @parents)

            # only one level of nesting
            @parents = []
          else
            router.add_resources klass
          end
        end

        return unless block

        @parents = classes

        block.call
      end
    end
  end
end
