# frozen_string_literal: true

require 'radical'

def require_all(dir)
  Dir[File.join(__dir__, dir, '*.rb')].sort.each do |file|
    require file
  end
end

Radical::Controller.prepend_view_path 'test'

require_all 'controllers'

class Routes < Radical::Routes
  root :HomeController
  resources :TodoController
  resources :TodoItemController
  resources :AsController, :BController

  resource :ProfileController

  resources :CController do
    resources :DController
  end
end

class App < Radical::App
  routes Routes
end
