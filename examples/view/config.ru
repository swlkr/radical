require '../../lib/radical'

class HomeController < Controller
  def index
    @page = 'index'

    view :index
  end

  def about
    @page = 'about'

    :about
  end
end

class App < Radical
  routes do
    get '/', to: 'home#index'
    get '/about', to: 'home#about'
  end
end

run App.new
