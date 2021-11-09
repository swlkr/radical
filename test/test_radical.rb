require 'minitest/autorun'
require 'radical'

Dir[File.join(__dir__, 'controllers', '*_controller.rb')].each do |file|
  require file
end

class RadicalTest < Minitest::Test
  def setup
    @app = App.new do
      get '/', to: 'home#index'
      get '/todos', to: 'todos#index'
    end
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
end
