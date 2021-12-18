# frozen_string_literal: true

class TodoItemController < Radical::Controller
  def new
    plain 'todo_item#new'
  end
end
