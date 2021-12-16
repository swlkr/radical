# frozen_string_literal: true

require 'minitest/autorun'
require 'radical'
require 'controllers/as'
require 'models/a'

class Whatever < Radical::Controller
  def index; end

  def edit; end
end

class TodoItem < Radical::Controller
end

class TodoItemsController < Radical::Controller
  def new; end
end

class TestRouter < Minitest::Test
  def setup
    @router = Radical::Router.new
  end

  def test_adds_resource_routes_when_methods_defined
    @router.add_resources(Whatever)

    assert_equal [[/^\/whatever$/, [Whatever, :index]], [/^\/whatever\/(?<id>[a-zA-Z0-9_]+)\/edit$/, [Whatever, :edit]]], @router.routes['GET']
  end

  def test_long_route_name
    assert_equal 'todo_items', TodoItems.send(:route_name)
  end

  def test_long_route_name_with_controller_suffix
    assert_equal 'todo_items', TodoItemsController.send(:route_name)
  end

  def test_new_route_name
    @router.add_resources(TodoItemsController, parents: [As])

    assert TodoItemsController.new(Rack::Request.new({})).send(:new_as_todo_items_path, A.new)
  end
end
