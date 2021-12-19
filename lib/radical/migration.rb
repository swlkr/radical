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

        "create table #{name} ( #{table.columns.join(',')} )"
      end

      def drop_table(name)
        "drop table #{name}"
      end

      def migrate!(db:, version:)
        db.execute(@change&.call || @up&.call)
        db.execute 'insert into radical_migrations (version) values (?)', [version]
      end

      def rollback!(db:, version:)
        @rollback = true

        db.execute(@change&.call || @down&.call)
        db.execute 'delete from radical_migrations where version = ?', [version]
      end
    end
  end
end
