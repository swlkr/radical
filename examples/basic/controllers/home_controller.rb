require '../../lib/radical'

class HomeController < Controller
  def index
    render plain: 'home#index!'
  end
end
