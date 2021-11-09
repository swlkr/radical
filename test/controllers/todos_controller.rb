class TodosController < Controller
  def index
    render plain: 'todos'
  end
end
