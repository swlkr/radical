# frozen_string_literal: true

module Radical
  class Flash
    class SessionUnavailable < StandardError; end

    SESSION_KEY = 'rack.session'
    FLASH_KEY = '__FLASH__'

    class FlashHash
      def initialize(session)
        raise SessionUnavailable, 'No session variable found. Requires Rack::Session' unless session

        @session = session
      end

      def [](key)
        hash[key] ||= session.delete(key)
      end

      def []=(key, value)
        hash[key] = session[key] = value
      end

      def mark!
        @flagged = session.keys
      end

      def clear!
        @flagged.each { |k| session.delete(k) }
        @flagged.clear
      end

      private

      def hash
        @hash ||= {}
      end

      def session
        @session[FLASH_KEY] ||= {}
      end
    end

    def initialize(app)
      @app = app
    end

    def call(env)
      flash_hash ||= FlashHash.new(env[SESSION_KEY])

      flash_hash.mark!

      res = @app.call(env)

      flash_hash.clear!

      res
    end
  end
end
