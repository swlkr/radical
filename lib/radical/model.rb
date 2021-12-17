# frozen_string_literal: true

require_relative 'database'

module Radical
  class ModelNotFound < StandardError; end

  class Model
    class << self
      attr_accessor :table_name

      def db
        Database.connection
      end

      def table(name)
        self.table_name = name
      end

      def columns
        sql = "select name from pragma_table_info('#{table_name}');"

        @columns ||= db.execute(sql).map { |r| r['name'] }
      end

      def save_columns
        columns.reject { |c| %w[id created_at updated_at].include?(c) }
      end

      def find(id)
        sql = "select * from #{table_name} where id = ? limit 1"

        row = db.get_first_row sql, [id.to_i]

        raise ModelNotFound, 'Record not found' unless row

        new(row)
      end

      def all
        sql = "select * from #{table_name} order by id"

        rows = db.execute sql

        rows.map { |r| new(r) }
      end
    end

    def initialize(params = {})
      columns.each do |column|
        self.class.attr_accessor column.to_sym
        instance_variable_set "@#{column}", (params[column] || params[column.to_sym])
      end
    end

    def columns
      self.class.columns
    end

    def save_columns
      self.class.save_columns
    end

    def db
      self.class.db
    end

    def table_name
      self.class.table_name
    end

    def delete
      sql = "delete from #{table_name} where id = ? limit 1"

      db.execute sql, id.to_i

      self
    end

    def update(params)
      save_columns.each { |c| instance_variable_set("@#{c}", params[c]) }

      save
    end

    def save
      values = save_columns.map { |c| instance_variable_get("@#{c}") }

      if saved?
        sql = <<-SQL
          update #{table_name} set #{save_columns.map { |c| "#{c}=?" }.join(',')}#{save_columns.any? ? ',' : ''} updated_at = ? where id = ?
        SQL

        db.transaction do |t|
          t.execute sql, values + [Time.now.to_i, id]
          self.class.find(id)
        end
      else
        sql = <<-SQL
          insert into #{table_name} (
            #{save_columns.join(',')}
          )
          values (
            #{save_columns.map { '?' }.join(',')}
          )
        SQL

        sql = "insert into #{table_name} default values" if values.empty?

        db.transaction do |t|
          t.execute sql, values
          self.class.find t.last_insert_row_id
        end
      end
    end

    def saved?
      !id.nil?
    end
  end
end
