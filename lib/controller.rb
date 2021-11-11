# typed: true
require 'erb'
require 'rack/utils'
require 'sorbet-runtime'

class Controller
  extend T::Sig

  sig { params(env: Hash).void }
  def initialize(env)
    @env = env
  end

  def index; end

  def show; end

  def new; end

  def create; end

  def edit; end

  def update; end

  def destroy; end

  sig { params(status: T.any(Symbol, Integer)).returns(Array) }
  def head(status)
    response body: '', status: Rack::Utils::SYMBOL_TO_STATUS_CODE[status] || status
  end

  sig { returns(Hash) }
  def params
    @env[:params] || {}
  end

  sig { params(options: T.any(String, Symbol, Hash)).returns(Array) }
  def render(options)
    case options
    when Hash
      headers = if options[:plain]
                  { 'Content-Type' => 'text/plain' }
                elsif options[:json]
                  { 'Content-Type' => 'application/json' }
                elsif options[:xml]
                  { 'Content-Type' => 'application/xml' }
                elsif options[:raw]
                  {}
                end

      response body: options[:plain] || options[:json] || options[:xml], headers: T.must(headers)
    when String
      view options
    when Symbol
      view options
    end
  end

  sig { params(name: T.any(String, Symbol)).returns(Array) }
  def view(name)
    template = File.read("./views/#{self.class.to_s.gsub('Controller', '').downcase}/#{name}.erb")
    compiled_template = ERB.new(template)

    result = compiled_template.result(binding)

    response body: result, headers: { 'Content-Type' => 'text/html' }
  end

  private

  sig do
    params(
      body: String,
      status: Integer,
      headers: Hash
    ).returns(Array)
  end
  def response(body:, status: 200, headers: { 'Content-Type' => 'text/plain' })
    [status, headers, [body]]
  end
end
