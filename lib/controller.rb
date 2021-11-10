# typed: true
require 'sorbet-runtime'

class Controller
  extend T::Sig

  def initialize(env)
    @env = env
  end

  def index
    head :ok
  end

  def show
    head :ok
  end

  def new
    head :ok
  end

  def create; end

  def edit
    head :ok
  end

  def update; end

  def destroy; end

  sig { params(body: T.any(String, Symbol)).returns(Array) }
  def head(body)
    if %i[ok no_content].include?(body)
      response
    else
      response body
    end
  end

  sig { returns(Hash) }
  def params
    @env[:params]
  end

  sig { params(options: Hash).returns(Array) }
  def render(options = { plain: nil, status: 200, headers: { 'Content-Type' => 'text/plain' } })
    response(options[:plain])
  end

  private

  sig do
    params(
      body: String,
      status: Integer,
      headers: Hash
    ).returns(Array)
  end
  def response(body = nil, status: 200, headers: { 'Content-Type' => 'text/plain' })
    [status, headers, body ? [body] : []]
  end
end
