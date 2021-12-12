# frozen_string_literal: true

require 'brotli'
require 'digest'
require 'zlib'

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
end
