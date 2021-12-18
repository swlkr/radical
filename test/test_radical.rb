# frozen_string_literal: true

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

  def test_params_with_underscores
    get '/todos/abc_xyz/edit'

    assert last_response.ok?
    assert_equal 'todos#edit { id: abc_xyz }', last_response.body
  end

  def test_nested_shallow_routes
    get '/d/2'

    assert last_response.ok?
    assert_equal 'd:2', last_response.body
  end

  def test_nested_routes
    get '/c/1/d'

    assert last_response.ok?
    assert_equal 'c:1', last_response.body
  end

  def test_views
    get '/'
    assert last_response.ok?
    assert '<html><h1>home#index</h1></html>', last_response.body
  end

  def test_view_without_layout
    get '/profile'
    assert last_response.ok?
    assert '<h1>profile#show</h1>', last_response.body
  end
end
