require '../../lib/radical'

class Controller < Radical::Controller
  prepend_view_path '/var/app/examples/crud'
  layout 'layout'
end

class Model < Radical::Model
  database 'test.sqlite3'
  prepend_migrations_path '/var/app/examples/crud'
end

Radical::Database.migrate!
# Radical::Database.rollback!

class Todo < Model
  table 'todos'
end

class Todos < Controller
  # GET /todos
  def index
    @todos = Todo.all
  end

  # GET /todos/:id
  def show; end

  # GET /todos/new
  def new
    @todo = Todo.new
  end

  # POST /todos
  def create
    @todo = Todo.new(todo_params)

    if @todo.save
      flash[:success] = 'Todo saved successfully'
      redirect todos_path
    else
      view :new
    end
  end

  # GET /todos/:id/edit
  def edit; end

  # PUT or PATCH /todos/:id
  def update
    if todo.update(todo_params)
      redirect todos_path
    else
      view :edit
    end
  end

  # DELETE /todos/:id
  def destroy
    if todo.delete
      flash[:success] = 'Todo deleted successfully'
    else
      flash[:error] = 'Todo could not be deleted'
    end

    redirect todos_path
  end

  private

  def todo_params
    params['todos'].slice('name')
  end

  def todo
    @todo ||= Todo.find(params['id'])
  end
end

class App < Radical::App
  resources Todos
end

run App
