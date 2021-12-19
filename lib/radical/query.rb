# frozen_string_literal: true

require_relative 'database'
require_relative 'strings'

module Radical
  class Query
    attr_accessor :params

    def initialize(model_sym)
      @table_name = Strings.snake_case model_sym.to_s
      @model_sym = model_sym
      @params = []
      @parts = {
        select: ['*'],
        from: [@table_name],
        where: [],
        join: [],
        offset: [],
        limit: [],
        'order by' => [],
        'group by' => []
      }
    end

    def from(table_name)
      @parts[:from] << table_name

      self
    end

    def select(*columns)
      @parts[:select] = columns

      self
    end

    def where(string_or_hash, *params)
      case string_or_hash
      when Hash
        string_or_hash.each do |k, v|
          @parts[:where] << "#{k} = ?"
          @params << v
        end
      when String
        @parts[:where] << string_or_hash
        @params += params
      end

      self
    end

    def limit(num)
      @parts[:limit] = [num]

      self
    end

    def offset(num)
      @parts[:offset] = [num]

      self
    end

    def order(string_or_hash)
      case string_or_hash
      when Hash
        string_or_hash.each do |k, v|
          @parts['order by'] << "#{k} #{v}"
        end
      when String
        @parts['order by'] << string_or_hash
      end

      self
    end

    def group(*columns)
      @parts['group by'] += columns

      self
    end

    def count(column = nil)
      column = column.nil? ? '*' : [@table_name, column].map { |s| quote(s) }.join('.')
      @parts[:select] = "count(#{column})"

      model = Object.const_get @model_sym

      model.db.get_first_value to_sql, @params
    end

    def to_sql
      @parts.reject { |_, v| v.nil? || v.empty? }.map { |k, v| "#{k} #{flat(v)}" }.join(' ')
    end

    def all
      model = Object.const_get @model_sym

      rows.map { |r| model.new(r) }
    end

    def first
      model = Object.const_get @model_sym

      model.new model.db.get_first_row(to_sql, @params)
    end

    private

    def quote(str)
      "'#{str}'"
    end

    def flat(could_be_array)
      if could_be_array.is_a?(Array)
        could_be_array.join(', ')
      else
        could_be_array
      end
    end

    def rows
      @rows ||= Database.connection.execute to_sql, @params
    end
  end
end
