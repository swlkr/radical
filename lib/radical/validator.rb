# frozen_string_literal: true

module Radical
  class Validator
    class << self
      def present?(val)
        return unless val.nil? || val&.empty?

        'is not present'
      end
    end
  end
end
