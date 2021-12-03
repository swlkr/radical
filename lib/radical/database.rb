require 'sqlite3'
require_relative 'table'

module Radical
  class Database
    class << self
      attr_accessor :connection, :migrations_path

      def db
        connection
      end

      def migrate!
        @migrate = true

        db.execute 'create table if not exists radical_migrations ( version integer primary key )'

        pending_migrations.each do |migration|
          puts "Executing migration #{migration}"
          sql = eval File.read(migration)
          db.execute sql
          db.execute 'insert into radical_migrations (version) values (?)', [version(migration)]
        end
      end

      def rollback!
        @rollback = true

        db.execute 'create table if not exists radical_migrations ( version integer primary key )'

        migration = applied_migrations.last

        puts "Rolling back migration #{migration}"

        sql = eval File.read(migration)
        db.execute sql
        db.execute 'delete from radical_migrations where version = ?', [version(migration)]
      end

      def applied_versions
        sql = 'select * from radical_migrations order by version'
        rows = db.execute sql

        rows.map { |r| r['version'] }
      end

      def applied_migrations
        migrations.select { |f| applied_versions.include?(version(f)) }
      end

      def pending_migrations
        migrations.reject { |f| applied_versions.include?(version(f)) }
      end

      def migrations
        Dir[File.join(migrations_path || '.', 'db', 'migrations', '*.rb')].sort
      end

      def version(filename)
        filename.split(File::SEPARATOR).last.split('_').first.to_i
      end

      def migration(&block)
        block.call
      end

      def change(&block)
        @change = true

        block.call
      end

      def up(&block)
        block.call
      end

      def down(&block)
        block.call
      end

      def create_table(name, &block)
        return "drop table #{name}" if @change && @rollback

        table = Table.new(name)

        block.call(table)

        "create table #{name} ( id integer primary key, #{table.columns.join(',')} )"
      end
    end
  end
end
