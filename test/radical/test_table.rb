# frozen_string_literal: true

require 'minitest/autorun'
require 'radical/table'

module Radical
  class TestTable < Minitest::Test
    def setup
      @table = Table.new
    end

    def test_varchar
      @table.integer(:a)

      assert_equal 'a integer', @table.columns.first
    end

    def test_unique
      @table.integer(:b, unique: true)

      assert_equal 'b integer unique', @table.columns.first
    end

    def test_not_null
      @table.integer(:c, null: false)

      assert_equal 'c integer not null', @table.columns.first
    end

    def test_check
      @table.integer(:d, check: 'd > 3')

      assert_equal 'd integer check(d > 3)', @table.columns.first
    end

    def test_collate
      @table.text(:d, collate: 'nocase')

      assert_equal 'd text collate nocase', @table.columns.first
    end

    def test_limit
      @table.varchar(:e, limit: '255')

      assert_equal 'e varchar (255)', @table.columns.first
    end
  end
end
