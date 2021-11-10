require 'minitest/autorun'
require 'app'

class RadicalTest < Minitest::Test
  def setup
    @app = App.new
  end

  def teardown; end

  def test_app_returns_a_404_with_no_routes
    assert_equal [404, { 'Content-Type' => 'text/plain' }, ['404 Not Found']], @app.call({})
  end

  def test_returns_expected_status_code_from_route
    expected = [200, { 'Content-Type' => 'text/plain' }, []]
    actual = @app.call(
      {
        'PATH_INFO' => '/',
        'REQUEST_METHOD' => 'GET'
      }
    )

    assert_equal expected, actual
  end

  def test_returns_diff_route
    expected = [200, { 'Content-Type' => 'text/plain' }, ['todos']]
    actual = @app.call(
      {
        'PATH_INFO' => '/todos',
        'REQUEST_METHOD' => 'GET'
      }
    )

    assert_equal expected, actual
  end

  def test_routes_to_long_controller
    expected = [200, { 'Content-Type' => 'text/plain' }, ['todo_items_controller']]
    actual = @app.call(
      {
        'PATH_INFO' => '/todo-items/new',
        'REQUEST_METHOD' => 'GET'
      }
    )

    assert_equal expected, actual
  end

  def test_params
    expected = [200, { 'Content-Type' => 'text/plain' }, ['todos#edit id: 2']]
    actual = @app.call(
      {
        'PATH_INFO' => '/todos/2/edit',
        'REQUEST_METHOD' => 'GET'
      }
    )

    assert_equal expected, actual
  end
end
