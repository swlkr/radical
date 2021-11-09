class Controller
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

  # sig {params(response: String).returns(Array[T.any(Integer, Hash, T.nilable(String))])}
  def head(body)
    if %i[ok no_content].include?(body)
      response
    else
      response body
    end
  end

  def params
    @env[:params]
  end

  def render(options = { status: 200, headers: { 'Content-Type' => 'text/plain' } })
    response(options[:plain])
  end

  private

  def response(body = nil, status: 200, headers: { 'Content-Type' => 'text/plain' })
    [status, headers, body ? [body] : []]
  end
end
