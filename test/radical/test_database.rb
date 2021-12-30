# frozen_string_literal: true

require 'minitest/autorun'
require 'radical'

module Radical
  class A < Model; end

  class V < Model
    table false

    validates do
      present :title
      matches %r{/[A-Z]/}, :name
    end
  end

  class Y < Model; end

  class TestDatabase < Minitest::Test
    def setup
      Database.logger = false
      Database.connection_string ||= ':memory:'
      Database.execute 'create table if not exists y ( id integer primary key, name text )'
      Database.execute 'create table if not exists a ( id integer primary key )'

      @query = Query.new model: A
    end

    def teardown
      A.delete_all
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

    def test_default_parts
      assert_equal 'select * from a', @query.to_sql
    end

    def test_where
      @query.where('name is not null')

      assert_equal 'select * from a where name is not null', @query.to_sql
    end

    def test_where_with_hash
      @query.where(name: 'peter parker')

      assert_equal 'select * from a where name = ?', @query.to_sql
      assert_equal ['peter parker'], @query.params
    end

    def test_where_with_hash_and_limit
      @query.where(type: 'hero').limit(10)

      assert_equal 'select * from a where type = ? limit 10', @query.to_sql
      assert_equal ['hero'], @query.params
    end

    def test_all
      a = A.create

      assert_equal a.to_h, A.all.first.to_h
    end

    def test_count
      assert_equal 0, @query.count

      2.times do
        A.create
      end

      assert_equal 2, @query.count
    end

    def test_where_with_hash_and_array
      actual = @query.where(id: [1, 2, 3]).to_sql

      assert_equal 'select * from a where (id in (?,?,?))', actual
    end

    def test_where_with_hash_and_array_with_nil
      actual = @query.where(id: [1, 2, 3, nil]).to_sql

      assert_equal 'select * from a where (id in (?,?,?) or id is null)', actual
    end
  end
end
