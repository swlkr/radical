# frozen_string_literal: true

require 'sqlite3'
require_relative 'logger'
require_relative 'table'
require_relative 'migration'

module Radical
  class Database
    class << self
      attr_writer :connection_string, :logger
      attr_accessor :migrations_path

      def connection_string
        @connection_string || ENV['DATABASE_URL']
      end

      def connection
        @connection ||= SQLite3::Database.new(connection_string, { results_as_hash: true })
      end

      def prepend_migrations_path(path)
        self.migrations_path = path
      end

      def logger
        return if @logger == false

        default_logger = Logger.new($stdout)
        default_logger.progname = 'db'

        @logger || default_logger
      end

      def migration(file)
        context = Module.new
        context.class_eval(File.read(file), file)
        const = context.constants.find do |constant|
          context.const_get(constant).ancestors.include?(Radical::Migration)
        end

        context.const_get(const)
      end

      def migrate!
        execute 'create table if not exists radical_migrations ( version integer primary key )'

        pending_migrations.each do |file|
          puts "Executing migration #{file}"

          m = migration(file)
          v = version(file)

          execute m.migrate
          execute 'insert into radical_migrations (version) values (?)', [v]
        end
      end

      def rollback!
        execute 'create table if not exists radical_migrations ( version integer primary key )'

        file = applied_migrations.last

        puts "Rolling back migration #{file}"

        m = migration(file)
        v = version(file)

        execute m.rollback
        execute 'delete from radical_migrations where version = ?', [v]
      end

      def applied_versions
        sql = 'select * from radical_migrations order by version'
        rows = execute sql

        rows.map { |r| r['version'] }
      end

      def applied_migrations
        migrations.select { |f| applied_versions.include?(version(f)) }
      end

      def pending_migrations
        migrations.reject { |f| applied_versions.include?(version(f)) }
      end

      def migrations
        Dir[File.join(migrations_path || '.', 'migrations', '*.rb')].sort
      end

      def version(filename)
        filename.split(File::SEPARATOR).last.split('_').first.to_i
      end

      def transaction(&block)
        if connection.transaction_active?
          yield
        else
          logger&.info 'Database transaction started'
          connection.transaction(&block)
          logger&.info 'Database transaction end'
        end
      end

      def execute(sql, params = [])
        # TODO: logging options? maybe log4j?
        logger&.info "#{sql} #{params}"

        connection.execute sql, params
      end

      def get_first_value(sql, params = [])
        logger&.info "#{sql} #{params}"

        connection.get_first_value sql, params
      end

      def get_first_row(sql, params = [])
        logger&.info "#{sql} #{params}"

        connection.get_first_row sql, params
      end

      def last_insert_row_id
        logger&.info 'select last_insert_row_id()'

        connection.last_insert_row_id
      end

      def columns(table_name = nil)
        return @columns[table_name] if @columns

        sql = 'select sqlite_master.name as t, tables.name, tables.type from sqlite_master join pragma_table_info(sqlite_master.name) as tables'

        @columns ||= execute(sql)
                     .group_by { |r| r['t'] }
                     .transform_values do |v|
                       v.map { |v1| [v1['name'], v1['type']] }.to_h
                     end
      end
    end
  end

  if Database.connection_string && Database.connection
    Database.execute 'PRAGMA journal_model = WAL'
    Database.execute 'PRAGMA foreign_keys = ON'
    Database.columns
  end
end
