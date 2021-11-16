require 'radical'

class Todos < Radical::Controller
  # GET /todos
  def index
    plain 'todos#index'
  end

  # GET /todos/:id/edit
  def edit
    plain "todos#edit { id: #{params['id']} }"
  end
end
