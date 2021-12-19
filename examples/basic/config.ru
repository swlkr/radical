# frozen_string_literal: true

require '../../lib/radical'

class HomeController < Radical::Controller
  def index
    head :ok
  end
end

class Routes < Radical::Routes
  root :HomeController
end

class App < Radical::App
  routes Routes
end

run App
