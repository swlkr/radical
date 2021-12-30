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
        @columns ||= Database.columns table_name
      end

      sig { params(id: T.any(String, Integer)).returns(Model) }
      def find!(id)
        model = Query.new(model: self).where(id: id.to_i).limit(1).first

        raise ModelNotFound, 'Record not found' unless model

        model
      end

      sig { params(id: T.nilable(T.any(String, Integer))).returns(T.nilable(Model)) }
      def find(id)
        Query.new(model: self).where(id: id&.to_i).limit(1).first
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

      sig { returns(Model) }
      def last
        Query.new(model: self).order('id desc').limit(1).first
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

        one_name = Strings.snake_case(model_name.to_s)
        name = options[:as] || one_name
        table_name = options[:table_name] || one_name
        iv = "@#{name}"
        fk_column = "#{name}_id"
        fk_column_iv = "@#{name}_id"

        attr_reader fk_column

        define_method :"#{name}=" do |record|
          instance_variable_set iv, record
          instance_variable_set fk_column_iv, record&.id
        end

        define_method :"#{fk_column}=" do |id|
          @fk_changes ||= {}
          @fk_changes[fk_column] = true

          # coerce to nil
          id = nil if id.nil? || id&.to_s&.empty?

          instance_variable_set fk_column_iv, id
          instance_variable_set iv, id if id.nil?
        end

        define_method :"#{name}" do
          @fk_changes ||= {}

          fk = send(fk_column)

          return unless fk

          if @fk_changes[fk_column] || !@fk_changes.key?(fk_column)
            @fk_changes[fk_column] = false
            instance_variable_set(iv, Query.new(model_name: model_name, record: self).where("#{table_name}.id" => send(fk_column)).first)
          else
            instance_variable_get(iv)
          end
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

      def attr_writer?(column)
        instance_methods.include?(:"#{column}=")
      end

      def attr_reader?(column)
        instance_methods.include?(column.to_sym)
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

      def inspect
        columns.join("\n")
      end
    end

    attr_accessor :errors, :id

    sig { params(params: Hash).void }
    def initialize(params = {})
      @errors = {}

      table_params = {}
      table_params = columns.map { |c| [c, params[c]] }.to_h if self.class.table_name
      params = table_params.merge(params)

      load_attributes params
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

    def destroy
      delete
    end

    def delete
      sql = "delete from #{table_name} where id = ?"

      Database.execute sql, id

      self
    end

    def update(params)
      load_attributes params
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

    def inspect
      attr_str = to_h.map { |k, v| "  #{k} => #{v}" }.join("\n")

      "#{self} {\n#{attr_str}\n}"
    end

    private

    def load_attributes(params)
      @params = params
      @params.transform_keys!(&:to_s)

      @params.each do |k, v|
        accessorize k, v
      end
    end

    def accessorize(column, value)
      self.class.attr_writer column unless self.class.attr_writer?(column)
      self.class.attr_reader column unless self.class.attr_reader?(column)

      send("#{column}=", value)
    end

    def db_params
      columns.map do |column|
        [column, send(column)]
      end.to_h
    end

    def insert_or_update
      query = Query.new(record: self, model: self.class)
      exceptions = %w[id updated_at created_at]
      params = db_params.except(*exceptions)

      Database.transaction do
        if saved?
          query
            .where(id: id)
            .limit(1)
            .update_all params.merge('updated_at' => Time.now.to_i)

          reload
        else
          query.insert params
          load Database.last_insert_row_id
        end
      end

      true
    end
  end
end
