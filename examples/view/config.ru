# frozen_string_literal: true

require '../../lib/radical'

class Controller < Radical::Controller
  prepend_view_path '/var/app/examples/view'
end

class HomeController < Controller
  def index
    @page = 'home#index'
  end
end

class AboutController < Controller
  def index
    @page = 'about#index'
  end
end

class Routes < Radical::Routes
  root :HomeController
  resources :AboutController
end

class App < Radical::App
  routes Routes
end

run App
