require '../../lib/radical'

class Home < Radical::Controller
  def index
    head :ok
  end
end

class App < Radical::App
  root Home
end

run App
