require '../../lib/radical'

class Todos < Radical::Controller
  # GET /todos
  def index
    plain 'GET /todos'
  end

  # GET /todos/:id
  def show
    plain "GET /todos/#{params['id']}"
  end

  # GET /todos/new
  def new
    plain 'GET /todos/new'
  end

  # POST /todos
  def create
    plain 'POST /todos'
  end

  # GET /todos/:id/edit
  def edit
    plain "GET /todos/#{params['id']}/edit"
  end

  # PUT or PATCH /todos/:id
  def update
    plain "PUT/PATCH /todos/#{params['id']}"
  end

  # DELETE /todos/:id
  def destroy
    plain "DELETE /todos/#{params['id']}"
  end
end

class App < Radical::App
  resources Todos
end

run App
