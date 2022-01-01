# typed: true
# frozen_string_literal: true

require_relative 'router'

module Radical
  class Routes
    attr_accessor :router

    def initialize(&block)
      @router = Router.new
      @parents = []

      instance_eval(&block)
    end

    def root(name)
      klass = Object.const_get name

      @router.add_root klass
    end

    def resource(*names)
      names.each do |name|
        klass = Object.const_get name
        router.add_resource klass
      end
    end

    def resources(*names, &block)
      classes = names.map { |n| Object.const_get n }

      classes.each do |klass|
        if @parents.any?
          router.add_resources(klass, parents: @parents)

          # only one level of nesting
          @parents = []
        else
          router.add_resources klass
        end
      end

      return unless block

      @parents = classes

      yield if block
    end
  end
end
