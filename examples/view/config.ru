require '../../lib/radical'

class Controller < Radical::Controller
  prepend_view_path '/var/app/examples/view'
end

class Home < Controller
  def index
    @page = 'home#index'
  end
end

class About < Controller
  def index
    @page = 'about#index'
  end
end

class App < Radical::App
  root Home
  routes About
end

run App
