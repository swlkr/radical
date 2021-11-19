require 'minitest/autorun'
require 'rack/test'
require 'app'

class RadicalTest < Minitest::Test
  include Rack::Test::Methods

  def app
    App
  end

  def test_returns_404_when_route_not_found
    get '/404'

    assert last_response.not_found?
  end

  def test_returns_200_when_route_is_found
    get '/todos'

    assert last_response.ok?
    assert_equal 'todos#index', last_response.body
  end

  def test_routes_to_long_controller_name
    get '/todo_items/new'

    assert last_response.ok?
    assert_equal 'todo_items#new', last_response.body
  end

  def test_params
    get '/todos/2/edit'

    assert last_response.ok?
    assert_equal 'todos#edit { id: 2 }', last_response.body
  end
end
