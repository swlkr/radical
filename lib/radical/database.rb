# frozen_string_literal: true

require 'logger'
require 'sqlite3'
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
        conn = SQLite3::Database.new(connection_string)
        conn.results_as_hash = true

        @connection ||= conn
      end

      def prepend_migrations_path(path)
        self.migrations_path = path
      end

      def logger
        return if @logger.nil?

        @logger || Logger.new($stdout)
      end

      def db
        connection
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
        connection.transaction(&block)
      end

      def execute(sql, params = [])
        # TODO: logging options? maybe log4j?
        logger&.info "#{sql} #{params.join(',')}"

        connection.execute sql, params
      end

      def get_first_value(sql, params = [])
        logger&.info "#{sql} #{params.join(',')}"

        connection.get_first_value sql, params
      end

      def get_first_row(sql, params = [])
        logger&.info "#{sql} #{params.join(',')}"

        connection.get_first_row sql, params
      end

      def last_insert_row_id
        logger&.info 'select last_insert_row_id()'

        connection.last_insert_row_id
      end
    end
  end
end
