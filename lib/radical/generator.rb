# frozen_string_literal: true

require 'fileutils'
require 'securerandom'
require_relative 'strings'

module Radical
  class Generator
    def initialize(name, props)
      @name = name
      @props = props
    end

    def mvc
      route
      migration
      model
      views
      controller
    end

    def route
      file = File.join Dir.pwd, 'routes.rb'
      lines = File.readlines(file)
      index = lines.find_index { |line| line.end_with? 'Routes ||= Radical::Routes.new do' }
      lines.insert(index + 1, "  resources :#{camel_case}")

      File.open(file, 'r+') do |f|
        lines.each do |line|
          f.puts line
        end
      end
    end

    def migration(model: true)
      dir = File.join(Dir.pwd, 'migrations')
      FileUtils.mkdir_p dir

      template = instance_eval File.read(File.join(__dir__, 'generator', "#{model ? '' : 'blank_'}migration.rb"))
      migration_name = model ? "#{Time.now.to_i}_create_table_#{snake_case}.rb" : "#{Time.now.to_i}_#{snake_case}.rb"
      filename = File.join(dir, migration_name)

      write(filename, template)
    end

    def model
      template = instance_eval File.read File.join(__dir__, 'generator', 'model.rb')
      dir = File.join(Dir.pwd, 'models')
      FileUtils.mkdir_p dir
      filename = File.join(dir, "#{snake_case}.rb")

      write(filename, template)
    end

    def controller
      template = instance_eval File.read File.join(__dir__, 'generator', 'controller.rb')
      dir = File.join(Dir.pwd, 'controllers')
      FileUtils.mkdir_p dir
      filename = File.join(dir, "#{snake_case}_controller.rb")

      write(filename, template)
    end

    def views
      dir = File.join(Dir.pwd, 'views', snake_case)
      FileUtils.mkdir_p dir

      Dir[File.join(__dir__, 'generator', 'views', '*.rb')].sort.each do |template|
        contents = instance_eval File.read template
        filename = File.join(dir, "#{File.basename(template, '.rb')}.erb")

        write(filename, contents)
      end
    end

    def app
      @name = nil if @name == '.'
      parts = [Dir.pwd, @name].compact
      dir = File.join(*parts)
      FileUtils.mkdir_p dir

      %w[
        assets/css
        assets/js
        controllers
        migrations
        models
        views
      ].each do |d|
        puts "Creating directory #{d}"
        FileUtils.mkdir_p File.join(dir, d)
      end

      Dir[File.join(__dir__, 'generator', 'app', '**', '*.*')].sort.each do |template|
        contents = File.read(template)
        filename = File.join(dir, File.path(template).gsub("#{__dir__}#{File::SEPARATOR}generator#{File::SEPARATOR}app#{File::SEPARATOR}", ''))

        write(filename, contents)
      end

      # Explicitly include .env
      template = File.join(__dir__, 'generator', 'app', '.env')
      contents = instance_eval File.read(template)
      filename = File.join(dir, '.env')
      write(filename, contents)
    end

    private

    def write(filename, contents)
      if File.exist?(filename)
        puts "Skipped #{File.basename(filename)}"
      else
        File.write(filename, contents)
        puts "Created #{filename}"
      end
    end

    def camel_case
      Strings.camel_case @name
    end

    def snake_case
      Strings.snake_case @name
    end

    def columns(leading:)
      @props
        .map { |p| p.split(':') }
        .map { |name, type| "t.#{type} #{name}" }
        .join "\n#{' ' * leading}"
    end

    def th(leading:)
      props = @props + %w[id created_at updated_at]

      props
        .map { |p| p.split(':').first }
        .map { |name| "<th>#{name}</th>" }
        .join "\n#{' ' * leading}"
    end

    def td(leading:)
      props = @props + %w[id created_at updated_at]

      props
        .map { |p| p.split(':').first }
        .map { |name| "<td><%= #{snake_case}.#{name} %></td>" }
        .join "\n#{' ' * leading}"
    end

    def inputs(leading:)
      @props
        .map { |p| p.split(':').first }
        .map { |name| "<%== f.text :#{name} %>" }
        .join "\n#{' ' * leading}"
    end

    def params
      @props
        .map { |p| p.split(':').first }
        .map { |name| "'#{name}'" }
        .join ', '
    end
  end
end
