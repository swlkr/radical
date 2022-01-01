# frozen_string_literal: true

require 'radical'
require 'minitest/autorun'
require 'models/a'

module Radical
  class TestRoutes < Minitest::Test
    def setup
      @routes = Routes.new do
        resource :AsController
        root :HomeController

        resources :BController do
          resources :CController
        end
      end

      req = Rack::Request.new({})

      @as = AsController.new req
      @b = BController.new req
    end

    def test_root_path
      assert Controller.method_defined?(:index_home_path)
    end

    def test_resource_paths
      %i[show_as_path new_as_path create_as_path edit_as_path update_as_path destroy_as_path].each do |method|
        assert Controller.method_defined?(method)
      end

      assert_equal '/as', @as.send(:show_as_path)
      assert_equal '/as/edit', @as.send(:edit_as_path)
      assert_equal '/as/new', @as.send(:new_as_path)
      assert_equal '/as', @as.send(:create_as_path)
      assert_equal '/as', @as.send(:update_as_path)
      assert_equal '/as', @as.send(:destroy_as_path)
    end

    def test_resources_paths
      %i[index_b_path show_b_path new_b_path create_b_path edit_b_path update_b_path destroy_b_path].each do |method|
        assert Controller.method_defined?(method)
      end

      m = ModelTest.new(id: 1)

      assert_equal '/b', @b.send(:index_b_path)
      assert_equal '/b/1', @b.send(:show_b_path, m)
      assert_equal '/b/1/edit', @b.send(:edit_b_path, m)
      assert_equal '/b/new', @b.send(:new_b_path)
      assert_equal '/b', @b.send(:create_b_path)
      assert_equal '/b/1', @b.send(:update_b_path, m)
      assert_equal '/b/1', @b.send(:destroy_b_path, m)
    end

    def test_nested_paths
      assert BController.method_defined?(:index_b_path)
      assert CController.method_defined?(:index_b_c_path)
      assert CController.method_defined?(:new_b_c_path)
    end
  end
end
