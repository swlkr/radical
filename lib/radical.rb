require_relative './router'
require_relative './controller'

# The main entry point for a radical application
#
# Example:
#
# class App < Radical
#   routes do
#     get '/', to: 'home#index'
#   end
# end
#
# app = App.new
# app.call(
#   {
#     'PATH_INFO' => '/',
#     'REQUEST_METHOD' => 'GET'
#   }
# ) # => 'home#index'
#
# Dispatches to:
#
# class HomeController < Controller
#   def index
#     render plain: 'home#index'
#   end
# end
class Radical
  class << self
    attr_accessor :router

    def routes(&block)
      @router = Router.new(&block)
    end
  end

  def call(env)
    self.class.router.route(env)
  end
end
