# frozen_string_literal: true

require 'fileutils'

module Radical
  class Generator
    def initialize(name, props)
      @name = name
      @props = props
    end

    def mvc
      migration
      model
      views
      controller
    end

    def migration(model: true)
      dir = File.join(Dir.pwd, 'migrations')
      FileUtils.mkdir_p dir

      template = instance_eval File.read(File.join(__dir__, 'generator', "#{model ? '' : 'blank_'}migration.rb"))
      migration_name = model ? "#{Time.now.to_i}_create_table_#{plural}.rb" : "#{Time.now.to_i}_#{@name}.rb"
      filename = File.join(dir, migration_name)

      write(filename, template)
    end

    def model
      template = instance_eval File.read File.join(__dir__, 'generator', 'model.rb')
      dir = File.join(Dir.pwd, 'models')
      FileUtils.mkdir_p dir
      filename = File.join(dir, "#{singular}.rb")

      write(filename, template)
    end

    def controller
      template = instance_eval File.read File.join(__dir__, 'generator', 'controller.rb')
      dir = File.join(Dir.pwd, 'controllers')
      FileUtils.mkdir_p dir
      filename = File.join(dir, "#{plural}.rb")

      write(filename, template)
    end

    def views
      dir = File.join(Dir.pwd, 'views', plural)
      FileUtils.mkdir_p dir

      Dir[File.join(__dir__, 'generator', 'views', '*.rb')].sort.each do |template|
        contents = instance_eval File.read template
        filename = File.join(dir, "#{File.basename(template, '.rb')}.erb")

        write(filename, contents)
      end
    end

    private

    def write(filename, contents)
      if File.exist?(filename)
        puts "Skipped #{File.basename(filename)}"
      else
        File.write(filename, contents)
      end
    end

    def singular_constant
      @name.gsub(/\(.*\)/, '')
    end

    def plural_constant
      @name.gsub(/[)(]/, '')
    end

    def singular
      @name.gsub(/\(.*\)/, '').gsub(/([A-Z])/, '_\1')[1..].downcase
    end

    def plural
      @name.gsub(/[)(]/, '').gsub(/([A-Z])/, '_\1')[1..].downcase
    end

    def columns(leading:)
      @props
        .map { |p| p.split(':') }
        .map { |name, type| "t.#{type} #{name}" }
        .join "#{' ' * leading}\n"
    end

    def th(leading:)
      @props
        .map { |p| p.split(':').first }
        .map { |name| "<th>#{name}</th>" }
        .join "#{' ' * leading}\n"
    end

    def td(leading:)
      @props
        .map { |p| p.split(':').first }
        .map { |name| "<td><%= #{singular}.#{name} %></td>" }
        .join "#{' ' * leading}\n"
    end

    def inputs(leading:)
      @props
        .map { |p| p.split(':').first }
        .map { |name| "<%== f.text :#{name} %>" }
        .join "#{' ' * leading}\n"
    end

    def params
      @props
        .map { |p| p.split(':').first }
        .map { |name| "'#{name}'" }
        .join ', '
    end
  end
end
