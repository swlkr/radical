# frozen_string_literal: true

module Radical
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
end
