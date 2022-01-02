# frozen_string_literal: true

require 'securerandom'

module Radical
  class SecurityHeaders
    DEFAULT_HEADERS = {
      'X-Content-Type-Options' => 'nosniff',
      'X-Frame-Options' => 'deny',
      'X-XSS-Protection' => '1; mode=block',
      'X-Permitted-Cross-Domain-Policies' => 'none',
      'Strict-Transport-Security' => 'max-age=31536000;, max-age=31536000; includeSubdomains',
      'Content-Security-Policy' => "default-src 'none'; style-src 'self'; script-src 'self'; connect-src 'self'; img-src 'self'; font-src 'self'; form-action 'self'; base-uri 'none'; frame-ancestors 'none'; block-all-mixed-content;"
    }.freeze

    def initialize(app, headers)
      @app = app
      @nonce = nonce
      csp_header = csp('script-src' => "nonce-#{@nonce}", 'style-src' => "nonce-#{@nonce}")
      @headers = DEFAULT_HEADERS.merge(csp_header).merge(headers)
    end

    def call(env)
      env['radical.nonce'] = @nonce

      @app.call(env).tap do |_, headers|
        @headers.each do |k, v|
          headers[k] ||= v
        end
      end
    end

    private

    def csp(options = {})
      default_options = {
        'default-src' => 'self',
        'style-src' => 'self',
        'script-src' => 'self',
        'connect-src' => 'self',
        'img-src' => 'self',
        'font-src' => 'self',
        'form-action' => 'self',
        'base-uri' => 'none',
        'frame-ancestors' => 'none',
        'block-all-mixed-content' => ''
      }

      { 'Content-Security-Policy' => default_options.merge(options).map { |k, v| "#{k} '#{v}'" }.join('; ') }
    end

    def nonce
      SecureRandom.hex(32)
    end
  end
end
