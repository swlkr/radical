# frozen_string_literal: true

module Radical
  class Migration
    class << self
      def change(&block)
        @change = block
      end

      def up(&block)
        @up = block
      end

      def down(&block)
        @down = block
      end

      def create_table(name, &block)
        return drop_table(name) if @change && @rollback

        table = Table.new

        block.call(table)

        "create table #{name} ( #{(table.columns + table.foreign_keys).join(',')} )"
      end

      def drop_table(name)
        "drop table #{name}"
      end

      def migrate
        @rollback = false

        @change&.call || @up&.call
      end

      def rollback
        @rollback = true

        @change&.call || @down&.call
      end
    end
  end
end
