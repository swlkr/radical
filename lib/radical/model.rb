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

      sig { returns(T.class_of(Database)) }
      def db
        Database
      end

      sig { params(name: T.any(String, Symbol, T::Boolean)).void }
      def table(name)
        @table_name = name
      end

      sig { returns(T.nilable(String)) }
      def table_name
        return if @table_name == false

        @table_name || Strings.snake_case(to_s.split('::').last)
      end

      sig { returns(T::Array[String]) }
      def columns
        sql = "select name from pragma_table_info('#{table_name}');"

        @columns ||= db.execute(sql).map { |r| r['name'] }
      end

      sig { params(id: T.any(String, Integer)).returns(Model) }
      def find!(id)
        model = Query.new(model: self).where(id: id.to_i).limit(1).first

        raise ModelNotFound, 'Record not found' unless model

        model
      end

      sig { params(id: T.any(String, Integer)).returns(Model) }
      def find(id)
        Query.new(model: self).where(id: id.to_i).limit(1).first
      end

      sig { returns(T::Array[Model]) }
      def all
        Query.new(model: self).order('id desc').all
      end

      sig { returns(Integer) }
      def count
        Query.new(model: self).count
      end

      sig { returns(Model) }
      def first
        Query.new(model: self).order('id').limit(1).first
      end

      def many(model_name, options = {})
        @many ||= []
        @many << model_name

        name = options[:as] || Strings.snake_case(model_name.to_s)
        foreign_key = options[:foreign_key] || "#{table_name}_id"

        define_method :"#{name}" do
          Query.new(model_name: model_name, record: self).where(foreign_key => send(:id))
        end
      end

      def one(model_name, options = {})
        @one ||= []
        @one << model_name

        name = options[:as] || Strings.snake_case(model_name.to_s)

        define_method :"#{name}" do
          Query.new(model_name: model_name, record: self).where("#{table_name}.id" => send(:"#{name}_id")).first
        end
      end

      def where(string_or_hash, *params)
        Query.new(model: self).where(string_or_hash, *params)
      end

      def create(params = {})
        record = new(params)
        record.save

        record
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

      def delete_all
        Query.new(model: self).delete_all
      end

      def find_by(params)
        Query.new(model: self).where(params).first
      end
    end

    attr_accessor :errors, :id

    sig { params(params: Hash).void }
    def initialize(params = {})
      @errors = {}

      load_params params
    end

    def columns
      self.class.columns
    end

    def db
      self.class.db
    end

    def table_name
      self.class.table_name
    end

    def delete
      sql = "delete from #{table_name} where id = ? limit 1"

      db.execute sql, id

      self
    end

    def update(params)
      load_params(params)
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

      insert_or_update
    end

    def save!(skip_validations: false)
      unless skip_validations
        validate
        raise ModelInvalid, "#{self} is invalid. Check the errors attribute" if invalid?
      end

      insert_or_update
    end

    def reload
      load id
    end

    def load(id)
      row = self.class.find id

      columns.each do |column|
        accessorize(column, row.send(column))
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

    private

    def load_params(params)
      @params = params.transform_keys(&:to_s).map do |column, value|
        if value.is_a?(Model)
          column = "#{column}_id"
          value = value.id
        end

        [column, value]
      end.to_h

      @params.each do |column, value|
        accessorize(column, value)
      end
    end

    def accessorize(column, value)
      self.class.attr_accessor column unless self.class.accessor?(column)
      instance_variable_set "@#{column}", value
    end

    def insert_or_update
      query = Query.new(record: self, model: self.class)

      Database.transaction do
        if saved?
          query
            .where(id: id)
            .limit(1)
            .update_all @params.except('id', 'created_at').merge('updated_at' => Time.now.to_i)

          reload
        else
          query.insert(@params)
          load Database.last_insert_row_id
        end
      end

      true
    end
  end
end
