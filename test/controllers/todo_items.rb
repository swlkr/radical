# frozen_string_literal: true

class TodoItems < Radical::Controller
  def new
    plain 'todo_items#new'
  end
end
