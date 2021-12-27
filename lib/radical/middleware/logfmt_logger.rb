# frozen_string_literal: true

module Radical
  module Middleware
    class LogfmtLogger
      def initialize(app)
        @app = app
        @formatter = LogFmtFormatter.new
      end

      def call(env)
        @logger = env[Rack::RACK_ERRORS]

        timestamp = Time.now.strftime('%Y-%m-%d %H:%M:%S.%L')
        @logger << logfmt(timestamp, { level: 'info', in: 'app', msg: 'Request started' })

        began_at = Rack::Utils.clock_time
        status, headers, body = @app.call(env)
        headers = Rack::Utils::HeaderHash[headers]
        body = Rack::BodyProxy.new(body) do
          log(env, status, headers, began_at)
        end

        [status, headers, body]
      end

      private

      def log(env, status, headers, began_at)
        length = extract_content_length(headers)

        parts = {
          level: 'info',
          in: 'app',
          msg: 'Request finished',
          status: status.to_s[0..3],
          method: env[Rack::REQUEST_METHOD],
          path: env[Rack::PATH_INFO],
          query_string: env[Rack::QUERY_STRING].empty? ? '' : "?#{env[Rack::QUERY_STRING]}",
          duration: format('%0.4f', Rack::Utils.clock_time - began_at),
          content_length: length,
          remote_addr: env['HTTP_X_FORWARDED_FOR'] || env['REMOTE_ADDR'],
          remote_user: env['REMOTE_USER'],
          script_name: env[Rack::SCRIPT_NAME],
          protocol: env[Rack::SERVER_PROTOCOL],
          host: env[Rack::HTTP_HOST]
        }

        timestamp = Time.now.strftime('%Y-%m-%d %H:%M:%S.%L')

        @logger << logfmt(timestamp, parts)
        @logger << "\n"
      end

      # Attempt to determine the content length for the response to
      # include it in the logged data.
      def extract_content_length(headers)
        value = headers[Rack::CONTENT_LENGTH]

        !value || value.to_s == '0' ? '' : value
      end

      def logfmt(timestamp, parts)
        "[#{timestamp}] #{parts.reject { |_, v| v.nil? || v&.to_s&.empty? }.map { |k, v| "#{k}=#{v}" }.join(' ')}\n"
      end
    end
  end
end
