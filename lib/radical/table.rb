# frozen_string_literal: true

module Radical
  class Table
    attr_accessor :columns

    def initialize
      @columns = []
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

    def timestamps
      @columns << "created_at integer not null default(strftime('%s', 'now'))"
      @columns << 'updated_at integer'
    end

    private

    def column_options(options = {})
      parts = []

      parts << "(#{options[:limit]})" if options[:limit]
      parts << 'unique' if options[:unique]
      parts << 'not null' if options[:null] == false
      parts << "default #{options[:default]}" if options[:default]
      parts << "check(#{options[:check]})" if options[:check]
      parts << "collate #{options[:collate]}" if options[:collate]

      parts.join(' ')
    end
  end
end
