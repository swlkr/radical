# typed: true

module Radical
  class Env
    class << self
      def radical_env
        ENV['RADICAL_ENV'] || ''
      end

      def development?
        radical_env.downcase == 'development'
      end

      def test?
        radical_env.downcase == 'test'
      end

      def production?
        radical_env.downcase == 'production'
      end
    end
  end
end
