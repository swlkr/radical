require 'radical'

require_relative 'controllers/home'
require_relative 'controllers/profile'
require_relative 'controllers/todos'
require_relative 'controllers/todo_items'

class App < Radical::App
  root Home
  resources Todos
  resources TodoItems
  resource Profile
end
