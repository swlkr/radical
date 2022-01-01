# frozen_string_literal: true

require 'minitest/autorun'
require 'rack/test'
require 'radical'

def require_all(dir)
  Dir[File.join(__dir__, dir, '*.rb')].sort.each do |file|
    require file
  end
end

require_all 'controllers'

Radical::Controller.prepend_view_path 'test'

class RadicalTest < Minitest::Test
  include Rack::Test::Methods

  def app
    @app ||= Radical::App.new(
      routes: Radical::Routes.new do
        root :HomeController
        resources :TodoController
        resources :TodoItemController
        resources :AsController, :BController

        resource :ProfileController

        resources :CController do
          resources :DController
        end
      end
    )
  end

  def test_raises_404_when_route_not_found
    assert_raises Radical::RouteNotFound do
      get '/404'
    end
  end

  def test_returns_200_when_route_is_found
    get '/todo'

    assert last_response.ok?
    assert_equal 'todo#index', last_response.body
  end

  def test_routes_to_long_controller_name
    get '/todo_item/new'

    assert last_response.ok?
    assert_equal 'todo_item#new', last_response.body
  end

  def test_params
    get '/todo/2/edit'

    assert last_response.ok?
    assert_equal 'todo#edit { id: 2 }', last_response.body
  end

  def test_params_with_underscores
    get '/todo/abc_xyz/edit'

    assert last_response.ok?
    assert_equal 'todo#edit { id: abc_xyz }', last_response.body
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
    assert_equal '<html><h1>home#index</h1></html>', last_response.body
  end

  def test_view_without_layout
    get '/profile'
    assert last_response.ok?
    assert_equal '<h1>profile#show</h1>', last_response.body
  end
end
