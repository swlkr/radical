# frozen_string_literal: true

require '../../lib/radical'

class Home < Radical::Controller
  def index
    redirect todos_path
  end
end

class Todos < Radical::Controller
  def index
    plain '/todos'
  end
end

class Routes < Radical::Routes
  root :Home
  resources :Todos
end

class App < Radical::App
  routes Routes
end

run App
