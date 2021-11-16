require 'minitest/autorun'
require 'app'

class NoRoutesApp < Radical::App
end

class RadicalTest < Minitest::Test
  def setup
    @app = App.new
  end

  def teardown; end

  def test_app_returns_a_404_with_no_routes
    no_routes_app = NoRoutesApp.new

    assert_equal [404, {}, []], no_routes_app.call({})
  end

  def test_returns_404_when_route_not_found
    expected = [404, {}, ['404 Not Found']]
    actual = @app.call(
      {
        'PATH_INFO' => '/404',
        'REQUEST_METHOD' => 'GET'
      }
    )

    assert_equal expected, actual
  end

  def test_returns_200_when_route_is_found
    expected = [200, { 'Content-Type' => 'text/plain' }, ['todos#index']]
    actual = @app.call(
      {
        'PATH_INFO' => '/todos',
        'REQUEST_METHOD' => 'GET'
      }
    )

    assert_equal expected, actual
  end

  def test_routes_to_long_controller_name
    expected = [200, { 'Content-Type' => 'text/plain' }, ['todo_items#new']]
    actual = @app.call(
      {
        'PATH_INFO' => '/todo_items/new',
        'REQUEST_METHOD' => 'GET'
      }
    )

    assert_equal expected, actual
  end

  def test_params
    expected = [200, { 'Content-Type' => 'text/plain' }, ['todos#edit { id: 2 }']]
    actual = @app.call(
      {
        'PATH_INFO' => '/todos/2/edit',
        'REQUEST_METHOD' => 'GET'
      }
    )

    assert_equal expected, actual
  end
end
