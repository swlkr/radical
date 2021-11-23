require 'minitest/autorun'
require 'radical'

class Whatever < Radical::Controller
  def index; end
  def edit; end
end

class TestRouter < Minitest::Test
  def setup
    @router = Radical::Router.new
  end

  def test_adds_resource_routes_when_methods_defined
    @router.add_routes(Whatever)

    assert_equal [[/^\/whatever$/, [Whatever, :index]], [/^\/whatever\/(?<id>[a-zA-Z0-9]+)\/edit$/, [Whatever, :edit]]], @router.routes['GET']
  end
end
