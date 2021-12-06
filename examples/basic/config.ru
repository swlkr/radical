# frozen_string_literal: true

require '../../lib/radical'

class Home < Radical::Controller
  def index
    head :ok
  end
end

class Routes < Radical::Routes
  root :Home
end

class App < Radical::App
  routes Routes
end

run App
