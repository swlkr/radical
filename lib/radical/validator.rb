# frozen_string_literal: true

module Radical
  class Validator
    def initialize(method, option = nil)
      @method = method
      @option = option
    end

    def validate(val)
      case @method
      when :present?
        present?(val)
      when :matches?
        matches?(@option, val)
      end
    end

    def present?(val)
      return unless val.nil? || val&.to_s&.empty?

      'is not present'
    end

    def matches?(re, val)
      result = re =~ val

      return if result

      'does not match'
    end
  end
end
