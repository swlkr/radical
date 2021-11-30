require 'minitest/autorun'
require 'radical'

class Whatever < Radical::Controller
  def index; end
  def edit; end
end

class A < Radical::Controller
end

class B < Radical::Controller
end

class TodoItem < Radical::Controller
end

class TestRouter < Minitest::Test
  def setup
    @router = Radical::Router.new
  end

  def test_adds_resource_routes_when_methods_defined
    @router.add_routes([Whatever])

    assert_equal [[/^\/whatever$/, [Whatever, :index]], [/^\/whatever\/(?<id>[a-zA-Z0-9_]+)\/edit$/, [Whatever, :edit]]], @router.routes['GET']
  end

  def test_multiple_resources_arguments
    @router.add_routes([A, B])

    assert_equal [[/^\/a$/, [A, :index]], [/^\/b$/, [B, :index]]], @router.routes['GET']
  end

  def test_long_route_name
    assert_equal 'todo_items', @router.route_name(TodoItems)
  end
end
