# frozen_string_literal: true

require 'radical'
require 'minitest/autorun'
require 'models/a'

class TestRoutes < Minitest::Test
  def test_root_path
    assert Radical::Controller.method_defined?(:index_home_path)
  end

  def test_resource_paths
    Radical::Routes.resource :AsController

    %i[show_as_path new_as_path create_as_path edit_as_path update_as_path destroy_as_path].each do |method|
      assert Radical::Controller.method_defined?(method)
    end

    as = AsController.new Rack::Request.new({})

    assert_equal '/as', as.send(:show_as_path)
    assert_equal '/as/edit', as.send(:edit_as_path)
    assert_equal '/as/new', as.send(:new_as_path)
    assert_equal '/as', as.send(:create_as_path)
    assert_equal '/as', as.send(:update_as_path)
    assert_equal '/as', as.send(:destroy_as_path)
  end

  def test_resources_paths
    Radical::Routes.resource :AsController

    %i[index_as_path show_as_path new_as_path create_as_path edit_as_path update_as_path destroy_as_path].each do |method|
      assert Radical::Controller.method_defined?(method)
    end

    as = AsController.new Rack::Request.new({})
    a = A.new(id: 1)

    assert_equal '/as', as.send(:index_as_path)
    assert_equal '/as/1', as.send(:show_as_path, a)
    assert_equal '/as/1/edit', as.send(:edit_as_path, a)
    assert_equal '/as/new', as.send(:new_as_path)
    assert_equal '/as', as.send(:create_as_path)
    assert_equal '/as/1', as.send(:update_as_path, a)
    assert_equal '/as/1', as.send(:destroy_as_path, a)
  end

  def test_nested_paths
    Radical::Routes.resources :BController do
      Radical::Routes.resources :CController
    end

    assert BController.method_defined?(:index_b_path)
    assert CController.method_defined?(:index_b_c_path)
    assert CController.method_defined?(:new_b_c_path)
  end
end
