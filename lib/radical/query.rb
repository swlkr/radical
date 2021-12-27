# frozen_string_literal: true

require_relative 'database'
require_relative 'strings'

module Radical
  class Query
    attr_accessor :params

    def initialize(record: nil, model: nil)
      @record = record
      @model = model
      @table_name = Strings.snake_case model.table_name
      @params = []
      @parts = {
        update: [],
        set: [],
        insert: [],
        delete: [],
        select: ['*'],
        from: [@table_name],
        where: [],
        join: [],
        'order by' => [],
        'group by' => [],
        offset: [],
        limit: []
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

      Database.get_first_value to_sql, @params
    end

    def to_sql
      @parts.reject { |_, v| v.nil? || v.empty? }.map { |k, v| "#{k} #{join_if_array(v)}".strip }.join(' ')
    end

    def all
      rows.map { |r| @model.new(r) }
    end

    def first
      row = Database.get_first_row to_sql, @params

      @model.new row if row
    end

    def delete_all
      @parts[:delete] << ''
      @parts[:select] = []

      Database.execute to_sql, @params
    end

    def update_all(params = {})
      @parts[:update] << ''
      @parts[:select] = []
      params.each do |k, v|
        @parts[:set] << k
        @params << v
      end

      Database.execute to_sql, @params
    end

    def insert(params = {})
      @parts[:select] = []
      @parts[:insert] << "into #{@table_name}"
      @parts[:from] = []

      if params.empty?
        @parts[:insert][0] += ' default values'
      else
        @parts[:insert][0] += " (#{params.keys.join(',')})"
        @parts[:values] = "(#{params.keys.map { '?' }.join(',')})"
      end

      @params = params.values

      Database.execute to_sql, @params
    end

    def create(params = {})
      record = @model.new params.merge("#{@record.table_name}_id" => @record.id)
      record.save

      record
    end

    def each(&block)
      all.each(&block)
    end

    private

    def quote(str)
      "'#{str}'"
    end

    def join_if_array(could_be_array)
      if could_be_array.is_a?(Array)
        could_be_array.join(', ')
      else
        could_be_array
      end
    end

    def rows
      @rows ||= Database.execute to_sql, @params
    end
  end
end
