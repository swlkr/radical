# frozen_string_literal: true

require 'minitest/autorun'
require 'radical/query'

module Radical
  class A < Model; end

  class TestQuery < Minitest::Test
    def setup
      Database.connection_string ||= ':memory:'
      Database.logger = nil
      Database.execute 'create table if not exists a ( id integer primary key )'

      @query = Query.new model: A
    end

    def teardown
      Database.execute 'delete from a'
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
  end
end
