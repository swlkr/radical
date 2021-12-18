# frozen_string_literal: true

module Radical
  class Strings
    SNAKE_CASE_REGEX = /\B([A-Z])/.freeze

    class << self
      def snake_case(str)
        str.gsub(SNAKE_CASE_REGEX, '_\1').downcase
      end

      def camel_case(str)
        return str if str.include?('_')

        str.split('_').map(&:capitalize).join
      end
    end
  end
end
