# frozen_string_literal: true

require 'radical'

def require_all(dir)
  Dir[File.join(__dir__, dir, '*.rb')].sort.each do |file|
    require file
  end
end

Radical::Controller.prepend_view_path 'test'

require_all 'controllers'

class C < Radical::Controller
end

class D < Radical::Controller
  def index
    plain "c:#{params['c_id']}"
  end

  def show
    plain "d:#{params['id']}"
  end
end

class Routes < Radical::Routes
  root :Home
  resources :Todos
  resources :TodoItems
  resources :As, :B

  resource :Profile

  resources :C do
    resources :D
  end
end

class App < Radical::App
  routes Routes
end
