# frozen_string_literal: true

require '../../lib/radical'

class HomeController < Radical::Controller
  def index
    redirect todos_path
  end
end

class TodosController < Radical::Controller
  def index
    plain '/todos'
  end
end

class Routes < Radical::Routes
  root :HomeController
  resources :TodosController
end

class App < Radical::App
  routes Routes
end

run App
