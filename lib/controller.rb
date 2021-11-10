# typed: true

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

  # sig {params(body: String).returns(Array[T.any(Integer, Hash, Array(String))])}
  def head(body)
    if %i[ok no_content].include?(body)
      response
    else
      response body
    end
  end

  # sig {returns(Hash)}
  def params
    @env[:params]
  end

  # sig {params(options: T::Hash[Keyword, T.any(Integer, Hash)], status: Integer).returns(Array[T.any(Integer, Hash, Array(String))])}
  def render(options = { status: 200, headers: { 'Content-Type' => 'text/plain' } })
    response(options[:plain])
  end

  private

  # sig {params(body: String, status: Integer).returns(Array[T.any(Integer, Hash, Array(String))])}
  def response(body = nil, status: 200, headers: { 'Content-Type' => 'text/plain' })
    [status, headers, body ? [body] : []]
  end
end
