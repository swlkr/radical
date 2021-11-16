require 'radical'

class TodoItems < Radical::Controller
  def new
    plain 'todo_items#new'
  end
end
