# frozen_string_literal: true

require 'radical'

def require_all(dir)
  Dir[File.join(__dir__, dir, '*.rb')].sort.each do |file|
    require file
  end
end

require_all 'controllers'

class C < Radical::Controller
end

class D < Radical::Controller
  def show
    plain "c:#{params['c_id']}, d:#{params['id']}"
  end
end

class Routes < Radical::Routes
  root 'Home'
  resources 'Todos'
  resources 'TodoItems'
  resources 'A', 'B'

  resource 'Profile'

  resources 'C' do
    resources 'D'
  end
end

class App < Radical::App
  routes Routes
end
