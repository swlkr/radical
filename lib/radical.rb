require 'router'
require 'controller'

class App
  def initialize(&block)
    @router = Router.new(&block)
  end

  def call(env)
    @router.route(env)
  end
end
