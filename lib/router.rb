# typed: true

class Router
  extend T::Sig

  def initialize(&block)
    @routes = Hash.new { |hash, key| hash[key] = [] }

    instance_eval(&block)
  end

  # sig{params(path: String, to: String).returns(void)}
  def get(path, to:)
    add_route('GET', path, to)
  end

  # sig{params(path: String, to: String).returns(void)}
  def post(path, to:)
    add_route('POST', path, to)
  end

  # sig{params(verb: String, path: String, to: String).returns(void)}
  def add_route(verb, path, to)
    controller, method = to.split('#')
    controller = controller.split('_').map(&:capitalize).join

    path = Regexp.new("^#{path.gsub(/:(\w+)/, '(?<\1>[a-zA-Z0-9]+)')}$")

    @routes[verb] << [path, ["#{controller}Controller", method]]
  end

  # sig{params(env: Hash).returns(Array[T.any(Integer, Hash, T::Array[String])])}
  def route(env)
    path = env['PATH_INFO']
    method = env['REQUEST_METHOD']

    route, params = @routes[method].map do |r|
      [r, path.match(r.first)&.named_captures]
    end.first

    if route&.last
      controller_name, action = route.last
      klass = Object.const_get(controller_name)
      env = env.merge({ params: params })

      controller = klass.new(env)

      raise "No controller with #{controller_name} found" unless controller
      raise "No action #{action} in #{klass} found" unless controller.respond_to?(action)

      controller.public_send(action)
    else
      not_found
    end
  end

  private

  # sig{params(body: String).returns(Array[T.any(Integer, Hash, T::Array[String])])}
  def not_found(body = '404 Not Found')
    [404, { 'Content-Type' => 'text/plain' }, [body]]
  end
end
