# frozen_string_literal: true

require 'minitest/autorun'
require 'radical/query'

module Radical
  class TestQuery < Minitest::Test
    def setup
      @query = Query.new(:A)
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
  end
end
