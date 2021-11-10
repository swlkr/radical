require '../../lib/radical'

class TodosController < Controller
  def index
    render plain: 'todos#index'
  end

  def show
    render plain: "todos#show(#{params['id']})"
  end
end
