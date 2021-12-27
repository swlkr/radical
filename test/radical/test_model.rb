# frozen_string_literal: true

require 'minitest/autorun'
require 'radical/model'

module Radical
  class V < Model
    table false

    validates do
      present :title
      matches %r{/[A-Z]/}, :name
    end
  end

  class Y < Model; end

  class TestModel < Minitest::Test
    def setup
      Database.connection_string ||= ':memory:'
      Database.execute 'create table if not exists y ( id integer primary key, name text )'
      Database.logger = nil
    end

    def teardown
      Y.delete_all
    end

    def test_validation
      v = V.new(title: nil, name: 'name')
      v.validate

      assert v.invalid?
      assert v.title.nil?
      assert_equal 'name', v.name
      assert_equal ['is not present'], v.errors[:title]
      assert_equal ['does not match'], v.errors[:name]
    end

    def test_save_on_new_with_no_params
      y = Y.new
      y.save

      assert_equal 1, y.id
    end

    def test_save_on_new_with_params
      y = Y.new(name: 'y')
      y.save

      assert_equal 1, y.id
      assert_equal 'y', y.name
    end
  end
end
