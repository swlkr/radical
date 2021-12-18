# frozen_string_literal: true

require '../../lib/radical'

Radical::Database.prepend_migrations_path '/var/app/examples/crud'
Radical::Database.migrate!

class Todo < Radical::Model
end

class Controller < Radical::Controller
  prepend_view_path '/var/app/examples/crud'
end

class TodoController < Controller
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
      redirect todo_path, notice: 'Todo saved'
    else
      view :new
    end
  end

  # GET /todos/:id/edit
  def edit; end

  # PUT or PATCH /todos/:id
  def update
    if todo.update(todo_params)
      redirect todo_path, notice: 'Todo updated'
    else
      view :edit
    end
  end

  # DELETE /todos/:id
  def destroy
    todo.delete

    redirect todo_path, notice: 'Todo deleted'
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
  resources :Todo
end

class App < Radical::App
  routes Routes
end

run App
