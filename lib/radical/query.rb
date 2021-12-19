# frozen_string_literal: true

require_relative 'database'
require_relative 'strings'

module Radical
  class Query
    attr_accessor :params

    def initialize(model_sym)
      @parts = {
        select: ['*'],
        from: [Strings.snake_case(model_sym.to_s)],
        where: [],
        join: [],
        offset: [],
        limit: [],
        'group by' => []
      }

      @model_sym = model_sym
      @params = []
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

    def to_sql
      @parts.reject { |_, v| v.nil? || v.empty? }.map { |k, v| "#{k} #{flat(v)}" }.join(' ')
    end

    def all
      model = Object.const_get @model_sym

      @all ||= rows.map { |r| model.new(r) }
    end

    private

    def flat(string_or_array)
      case string_or_array
      when String
        string_or_array
      when Array
        string_or_array.join(', ')
      end
    end

    def rows
      @rows ||= Database.connection.execute to_sql, @params
    end
  end
end
