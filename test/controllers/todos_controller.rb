require 'radical'

class TodosController < Controller
  def index
    render plain: 'todos'
  end

  # GET /todos/:id/edit
  def edit
    render plain: "todos#edit id: #{params['id']}"
  end
end
