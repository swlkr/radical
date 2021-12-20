# frozen_string_literal: true

require_relative 'strings'

module Radical
  class Table
    attr_accessor :columns, :foreign_keys

    def initialize
      @columns = [
        'id integer primary key'
      ]

      @foreign_keys = []
    end

    %w[
      int
      integer
      tinyint
      smallint
      mediumint
      bigint
      unsigned_big_int
      int2
      int8
      character
      varchar
      varying_character
      nchar
      native_character
      nvarchar
      text
      clob
      blob
      real
      double
      double_precision
      float_real
      numeric
      decimal
      boolean
      date
      datetime
    ].each do |type|
      define_method :"#{type}" do |name, options = {}|
        @columns << [name, type, column_options(options)].compact.join(' ').strip
      end
    end

    def string(name, options = {})
      varchar(name, { limit: 255 }.merge(options))
    end

    def timestamps
      integer('created_at', null: false, default: "strftime('%s', 'now')")
      integer('updated_at')
    end

    def references(model_sym, options = {})
      table_name = Strings.snake_case model_sym.to_s

      integer("#{table_name}_id", options)

      @foreign_keys << [
        "foreign key(#{table_name}_id) references #{table_name}(id)",
        column_options(options.slice(:on_delete, :on_update))
      ].compact.join(' ').strip
    end

    private

    def column_options(options = {})
      parts = []

      parts << "(#{options[:limit]})" if options[:limit]
      parts << 'unique' if options[:unique]
      parts << 'not null' if options[:null] == false
      parts << "default(#{options[:default]})" if options[:default]
      parts << "check(#{options[:check]})" if options[:check]
      parts << "collate #{options[:collate]}" if options[:collate]
      parts << "on delete #{options[:on_delete]}" if options[:on_delete]
      parts << "on update #{options[:on_update]}" if options[:on_update]

      parts.join(' ')
    end
  end
end
