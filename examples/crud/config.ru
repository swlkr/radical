require '../../lib/radical'

class Todos < Radical::Controller
  # GET /todos
  def index
    plain 'todos#index'
  end

  # GET /todos/:id
  def show
    plain 'todos#show'
  end

  # GET /todos/new
  def new
    plain 'todos#new'
  end

  # POST /todos
  def create
    plain 'todos#create'
  end

  # GET /todos/:id/edit
  def edit
    plain 'todos#edit'
  end

  # PUT or PATCH /todos/:id
  def update
    plain 'todos#update'
  end

  # DELETE /todos/:id
  def destroy
    plain 'todos#destroy'
  end
end

class App < Radical::App
  resources Todos
end

run App
