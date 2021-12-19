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

      assert_equal 'a integer', @table.columns[1]
    end

    def test_unique
      @table.integer(:b, unique: true)

      assert_equal 'b integer unique', @table.columns[1]
    end

    def test_not_null
      @table.integer(:c, null: false)

      assert_equal 'c integer not null', @table.columns[1]
    end

    def test_check
      @table.integer(:d, check: 'd > 3')

      assert_equal 'd integer check(d > 3)', @table.columns[1]
    end

    def test_collate
      @table.text(:d, collate: 'nocase')

      assert_equal 'd text collate nocase', @table.columns[1]
    end

    def test_limit
      @table.varchar(:e, limit: '255')

      assert_equal 'e varchar (255)', @table.columns[1]
    end

    def test_pk
      assert_equal 'id integer primary key', @table.columns.first
    end

    def test_references
      @table.references :TodoItem

      assert_equal 'todo_item_id integer', @table.columns[1]
      assert_equal 'foreign key(todo_item_id) references todo_item(id)', @table.columns[2]
    end

    def test_string
      @table.string :name

      assert_equal 'name varchar (255)', @table.columns[1]
    end
  end
end
