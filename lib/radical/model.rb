# typed: true
# frozen_string_literal: true

require_relative 'database'
require_relative 'strings'
require_relative 'query'
require_relative 'validator'

module Radical
  class ModelNotFound < StandardError; end

  class ModelInvalid < StandardError; end

  class Model
    extend T::Sig

    class << self
      extend T::Sig

      sig { returns(SQLite3::Database) }
      def db
        Database.connection
      end

      sig { params(name: T.any(String, Symbol, T::Boolean)).void }
      def table(name)
        @table_name = name
      end

      sig { returns(T.nilable(String)) }
      def table_name
        return if @table_name == false

        @table_name || Strings.snake_case(to_s)
      end

      sig { returns(T::Array[String]) }
      def columns
        sql = "select name from pragma_table_info('#{table_name}');"

        @columns ||= db.execute(sql).map { |r| r['name'] }
      end

      sig { returns(T::Array[String]) }
      def save_columns
        columns.reject { |c| %w[id created_at updated_at].include?(c) }
      end

      def find!(id)
        row = Query.new(to_s).where(id: id.to_i).limit(1).first

        raise ModelNotFound, 'Record not found' unless row

        row
      end

      def find(id)
        Query.new(to_s).where(id: id.to_i).limit(1).first
      end

      def all
        Query.new(to_s).order('id desc').all
      end

      def count
        Query.new(to_s).count
      end

      def many(sym)
        @many ||= []
        @many << sym

        name = Strings.snake_case sym.to_s
        # TODO: do i really need inflections?
        define_method :"#{name}s" do
          Query.new(sym)
        end
      end

      def one(sym)
        @one ||= []
        @one << sym

        name = Strings.snake_case sym.to_s

        define_method :"#{name}" do
          Query.new(sym)
        end
      end

      def where(string_or_hash, *params)
        Query.new(to_s).where(string_or_hash, *params)
      end

      def create(hash = {})
        arr = hash.to_a

        sql = if hash.empty?
                "insert into '#{table_name}' default values"
              else
                "insert into '#{table_name}' ( #{arr.map(&:first).map { |_, s| "'#{s}'" }.join(', ')} ) values ( #{arr.map { '?' }.join(', ')} )"
              end

        params = arr.map(&:last)

        result = nil

        db.transaction do |t|
          if params
            t.execute sql, params
          else
            t.execute sql
          end

          result = find t.last_insert_row_id
        end

        result
      end

      def accessor?(column)
        instance_methods.include?(column.to_sym) ||
          instance_methods.include?(:"#{column}=")
      end

      def validations
        @validations ||= []
      end

      def validates(&block)
        block.call
      end

      def present(*attributes)
        validations << [[:present?], *attributes]
      end

      def matches(regex, *attributes)
        validations << [[:matches?, regex], *attributes]
      end
    end

    attr_accessor :errors

    sig { params(params: Hash).void }
    def initialize(params = {})
      @errors = {}

      @params = params
      @params.transform_keys!(&:to_s)
      @params = @params.slice(*columns.map(&:to_s)) if table_name

      @params.each do |k, v|
        self.class.attr_accessor k unless self.class.accessor?(k)
        instance_variable_set "@#{k}", v
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

      db.execute sql, @params['id']

      self
    end

    def update(params)
      save_columns.each { |c| instance_variable_set("@#{c}", params[c]) }

      save
    end

    def validate
      self.class.validations.each do |validation|
        validator_arr, *attributes = validation
        validator = Validator.new(*validator_arr)

        attributes.each do |attr|
          error = validator.validate public_send(attr)
          add_error(attribute: attr, message: error) if error
        end
      end
    end

    def add_error(attribute: nil, message: nil)
      if @errors[attribute]
        @errors[attribute] << message
      else
        @errors[attribute] = [message]
      end
    end

    def valid?
      @errors.empty?
    end

    def invalid?
      !valid?
    end

    sig { params(skip_validations: T::Boolean).returns(T::Boolean) }
    def save(skip_validations: false)
      unless skip_validations
        validate
        return false if invalid?
      end

      values = save_columns.map { |c| instance_variable_get("@#{c}") }

      if saved?
        sql = <<-SQL
          update #{table_name} set #{save_columns.map { |c| "#{c}=?" }.join(',')}#{save_columns.any? ? ',' : ''} updated_at = ? where id = ?
        SQL

        db.transaction do |t|
          t.execute sql, values + [Time.now.to_i, @params['id']]
          reload! @params['id']
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
          reload! t.last_insert_row_id
        end
      end

      true
    end

    def save!
      validate

      raise ModelInvalid, "#{self} is invalid. Check the errors attribute" if invalid?

      save
    end

    def reload!(id)
      row = self.class.find id

      self.class.columns.each do |column|
        instance_variable_set "@#{column}", row.send(column)
      end
    end

    def saved?
      !id.nil?
    end

    def to_h
      result = {}

      columns.each do |column|
        result[column] = instance_variable_get "@#{column}"
      end

      result
    end
  end
end
