# typed: true

require 'sorbet-runtime'

# A very naive router for radical
#
# This class loops over routes for each http method (GET, POST, etc.)
# and checks a simple regex built at startup
#
# '/users/:id' => "/users/:^#{path.gsub(/:(\w+)/, '(?<\1>[a-zA-Z0-9]+)')}$"
#
# Example:
#
# router = Router.new do
#   get '/users/:id', to: 'users#show'
# end
#
# router.route(
#   {
#     'PATH_INFO' => '/users/1',
#     'REQUEST_METHOD' => 'GET'
#   }
# ) => 'users#show(1)'
#
# Dispatches to:
#
# class UsersController < Controller
#   def show
#     render plain: "users#show(#{params['id']})"
#   end
# end
class Router
  extend T::Sig

  def initialize(&block)
    @routes = Hash.new { |hash, key| hash[key] = [] }

    instance_eval(&block)
  end

  sig { params(path: String, to: String).void }
  def get(path, to:)
    add_route('GET', path, to)
  end

  sig { params(path: String, to: String).void }
  def post(path, to:)
    add_route('POST', path, to)
  end

  sig { params(verb: String, path: String, to: String).void }
  def add_route(verb, path, to)
    controller, method = to.split('#')
    controller = controller&.split('_')&.map(&:capitalize)&.join

    path = Regexp.new("^#{path.gsub(/:(\w+)/, '(?<\1>[a-zA-Z0-9]+)')}$")

    @routes[verb] << [path, ["#{controller}Controller", method]]
  end

  sig { params(env: Hash).returns(Array) }
  def route(env)
    path = env['PATH_INFO']
    method = env['REQUEST_METHOD']
    params = T.let({}, T.nilable(Hash))

    route = @routes[method].find do |r|
      params = path.match(r.first)&.named_captures
    end

    if route&.last
      controller_name, action = route.last
      klass = Object.const_get(controller_name)
      env = env.merge({ params: params })

      controller = klass.new(env)

      raise "No controller with #{controller_name} found" unless controller
      raise "No action #{action} in #{klass} found" unless controller.respond_to?(action)

      response = controller.public_send(action)

      case response
      when String
        [200, { 'Content-Type' => 'text/plain' }, [response]]
      when Symbol
        controller.view(response)
      when Array
        response
      else
        not_found
      end
    else
      not_found
    end
  end

  private

  sig { params(body: String).returns(Array) }
  def not_found(body = '404 Not Found')
    [404, { 'Content-Type' => 'text/plain' }, [body]]
  end
end
