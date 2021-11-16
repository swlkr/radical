require 'puma'
require '../../lib/radical'

Radical::View.path '/var/app/examples/view'

class Home < Radical::Controller
  def index
    @page = 'home#index'
  end
end

class About < Radical::Controller
  def index
    @page = 'about#index'
  end
end

class App < Radical::App
  root Home
  routes About
end

run App.new.freeze
