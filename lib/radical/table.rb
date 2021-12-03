module Radical
  class Table
    attr_accessor :columns

    def initialize(table)
      @table = table
      @columns = []
    end

    def string(name)
      @columns << "#{name} text"
    end

    def integer(name)
      @columns << "#{name} integer"
    end

    def timestamps
      @columns << "created_at integer not null default(strftime('%s', 'now'))"
      @columns << 'updated_at integer'
    end
  end
end
