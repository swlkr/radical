class Router
  def initialize(&block)
    @routes = Hash.new { |hash, key| hash[key] = [] }

    instance_eval(&block)
  end

  # sig{.void}
  def get(path, to:)
    controller, method = to.split('#')
    @routes['GET'] << [path, ["#{controller.capitalize}Controller", method]]
  end

  def route(env)
    path = env['PATH_INFO']
    method = env['REQUEST_METHOD']
    # TODO: make this better
    route = @routes[method].find { |r| r.first == path }

    if route&.last
      controller_name, action = route.last
      klass = Object.const_get(controller_name)
      # add_route_info_to_request_params!

      controller = klass.new(env)

      raise "No controller with #{controller_name} found" unless controller
      raise "No action #{action} in #{klass} found" unless controller.respond_to?(action)

      # TODO: middleware?
      puts "\nRouting to #{klass}##{action}"

      controller.public_send(action)
    else
      not_found
    end
  end

  private

  def not_found(body = '404 Not Found')
    [404, { 'Content-Type' => 'text/plain' }, [body]]
  end

  #def find_id_and_action(fragment)
  #  case fragment
  #  when 'new'
  #    [nil, :new]
  #  when nil
  #    action = @request.get? ? :index : :create
  #    [nil, action]
  #  else
  #    [fragment, :show]
  #  end
  #end

  #def path_fragments
  #  (@fragments ||= @request.path).split("/").reject(&:empty?)
  #end

  #private

  #def add_route_info_to_request_params!
  #  @request.params.merge!(route_info)
  #end

  #def controller_class
  #  Object.const_get(controller_name)
  #rescue NameError
  #  raise "No controller with #{controller_name} found"
  #end

  #def controller_name
  #  "#{route_info[:resource].capitalize}Controller"
  #end
end
