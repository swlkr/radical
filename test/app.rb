require 'radical'

require_relative 'controllers/home'
require_relative 'controllers/todos'
require_relative 'controllers/todo_items'

class App < Radical::App
  routes Home
  routes Todos
  routes TodoItems
end
