# frozen_string_literal: true

require 'radical'

def require_all(*args)
  args.each do |arg|
    file = File.join(__dir__, arg)

    if File.exist?("#{file}.rb")
      require file
    else
      Dir[File.join(file, '*.rb')].sort.each do |f|
        require f
      end
    end
  end
end

require_all(
  'models/model',
  'models',
  'controllers/controller',
  'controllers',
  'routes'
)

App ||= Radical::App.new(
  routes: Routes,

  assets: {
    css: %w[],
    js: %w[]
  }
)

App.compile_assets if Radical.env.production?
