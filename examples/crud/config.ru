# frozen_string_literal: true

require '../../lib/radical'

Radical::Database.prepend_migrations_path '/var/app/examples/crud'
Radical::Database.migrate!

class Todo < Radical::Model
  table 'todos'
end

class Controller < Radical::Controller
  prepend_view_path '/var/app/examples/crud'
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
      flash[:success] = 'Todo updated successfully'
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

  def todo
    @todo ||= Todo.find params['id']
  end

  def todo_params
    params.slice('name')
  end
end

class Routes < Radical::Routes
  resources :Todos
end

class App < Radical::App
  routes Routes
end

run App
