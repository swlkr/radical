require '../../lib/radical'

Dir[File.join(__dir__, 'controllers', '*_controller.rb')].each do |file|
  require file
end

class App < Radical
  routes do
    get '/', to: 'home#index'
    get '/todos', to: 'todos#index'
    get '/todos/:id', to: 'todos#show'
  end
end
