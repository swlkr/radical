# frozen_string_literal: true

require_relative 'database'

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

      def migrate!(version:)
        Database.execute @change&.call || @up&.call
        Database.execute 'insert into radical_migrations (version) values (?)', [version]
      end

      def rollback!(version:)
        @rollback = true

        Database.execute @change&.call || @down&.call
        Database.execute 'delete from radical_migrations where version = ?', [version]
      end
    end
  end
end
