# frozen_string_literal: true

require 'brotli'
require 'digest'
require 'securerandom'
require 'rack'
require 'rack/flash'
require 'rack/csrf'
require 'zlib'

require_relative 'routes'
require_relative 'env'

# The main entry point for a Radical application
#
# Example:
#
# class App < Radical::App
#   root Home
# end
#
# App.call(
#   {
#     'PATH_INFO' => '/',
#     'REQUEST_METHOD' => 'GET'
#   }
# )
#
# Dispatches to:
#
# class Controller < Radical::Controller
#   # GET /
#   def index
#     head :ok
#   end
# end
module Radical
  class AssetCompiler
    def self.gzip(filename, content)
      # nil, 31 == support for gunzip
      File.write(filename, Zlib::Deflate.new(nil, 31).deflate(content, Zlib::FINISH))
    end

    def self.compile(assets, path:, compressor: :none)
      s = assets.map(&:content).join("\n")
      ext = assets.first.ext

      # hash the contents of each concatenated asset
      hash = Digest::SHA1.hexdigest s

      # use hash to bust the cache
      name = "#{hash}#{ext}"
      filename = File.join(path, name)

      case compressor
      when :gzip
        name = "#{name}.gz"
        gzip("#{filename}.gz", s)
      when :brotli
        name = "#{name}.br"
        File.write("#{filename}.br", Brotli.deflate(s, mode: :text, quality: 11))
      else
        File.write(filename, s)
      end

      # output asset path for browser
      "/assets/#{name}"
    end
  end

  class Asset
    attr_reader :path

    def initialize(filename, path:)
      @filename = filename
      @path = path
    end

    def full_path
      File.join(path, @filename)
    end

    def content
      File.read(full_path)
    end

    def ext
      File.extname(@filename)
    end
  end

  class Assets
    attr_accessor :assets_path, :compiled, :assets

    def initialize
      @assets = {
        css: [],
        js: []
      }
      @compressor = :none
      @assets_path = File.join(__dir__, 'assets')
      @compiled = {}
    end

    def css(filenames)
      @assets[:css] = filenames
    end

    def js(filenames)
      @assets[:js] = filenames
    end

    def prepend_assets_path(path)
      @assets_path = File.join(path, 'assets')
    end

    def brotli
      @compressor = :brotli
    end

    def gzip
      @compressor = :gzip
    end

    def compile
      css = @assets[:css].map { |f| Asset.new(f, path: File.join(@assets_path, 'css')) }
      js = @assets[:js].map { |f| Asset.new(f, path: File.join(@assets_path, 'js')) }

      @compiled[:css] = AssetCompiler.compile(css, path: @assets_path, compressor: @compressor)
      @compiled[:js] = AssetCompiler.compile(js, path: @assets_path, compressor: @compressor)
    end
  end

  class App
    class << self
      def routes(route_class)
        @routes = route_class
      end

      def assets(&block)
        @assets = Assets.new

        block.call(@assets)
      end

      def compile_assets
        @assets.compile
      end

      def serve_assets
        @serve_assets = true
      end

      def env
        Env
      end

      def app
        router = @routes.router
        env = self.env
        session_secret = self.session_secret
        assets = @assets
        serve_assets = @serve_assets

        @app ||= Rack::Builder.app do
          use Rack::CommonLogger
          use Rack::ShowExceptions if env.development?
          use Rack::Runtime
          use Rack::MethodOverride
          use Rack::ContentLength
          use Rack::Deflater
          use Rack::ETag
          use Rack::Head
          use Rack::ConditionalGet
          use Rack::ContentType
          use Rack::Session::Cookie, path: '/',
                                     secret: session_secret,
                                     http_only: true,
                                     same_site: :lax,
                                     secure: env.production?,
                                     expire_after: 2_592_000 # 30 days
          use Rack::Csrf, raise: env.development?, skip: router.routes.values.flatten.select { |a| a.is_a?(Class) }.uniq.map(&:skip_csrf_actions).flatten(1)
          use Rack::Flash, sweep: true

          if serve_assets || env.development?
            use Rack::Static, urls: ['/assets', '/public'],
                              header_rules: [
                                [/\.(?:css\.gz)$/, { 'Content-Type' => 'text/css', 'Content-Encoding' => 'gzip' }],
                                [/\.(?:js\.gz)$/, { 'Content-Type' => 'application/javascript', 'Content-Encoding' => 'gzip' }],
                                [/\.(?:css\.br)$/, { 'Content-Type' => 'text/css', 'Content-Encoding' => 'br' }],
                                [/\.(?:js\.br)$/, { 'Content-Type' => 'application/javascript', 'Content-Encoding' => 'br' }]
                              ]
          end

          run lambda { |rack_env|
            begin
              router.route(Rack::Request.new(rack_env), options: { assets: assets }).finish
            rescue ModelNotFound
              raise unless env.production?

              Rack::Response.new('404 Not Found', 404).finish
            end
          }
        end
      end

      def call(env)
        app.call(env)
      end

      private

      def session_secret
        @session_secret ||= (ENV['SESSION_SECRET'] || SecureRandom.hex(32))
      end
    end
  end
end
