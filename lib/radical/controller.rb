# typed: true
require 'erb'
require 'rack/utils'
require 'rack/request'
require 'rack/response'
require 'sorbet-runtime'
require_relative 'view'
require_relative 'env'

module Radical
  class Controller
    extend T::Sig
    sig { params(request: Rack::Request).void }
    def initialize(request)
      @request = request
    end

    sig { params(status: T.any(Symbol, Integer)).returns(Rack::Response) }
    def head(status)
      Rack::Response.new(nil, Rack::Utils::SYMBOL_TO_STATUS_CODE[status])
    end

    def plain(body)
      Rack::Response.new(body, 200, { 'Content-Type' => 'text/plain' })
    end

    sig { returns(Hash) }
    def params
      @request.params
    end

    sig { params(name: String).returns(String) }
    def view(name)
      dir = self.class.to_s.gsub(/([A-Z])/, '_\1')[1..-1].downcase
      view = View.compiled(dir, name)

      view&.result(binding)
    end
  end
end
