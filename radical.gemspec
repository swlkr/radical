# frozen_string_literal: true

Gem::Specification.new do |spec|
  spec.platform      = Gem::Platform::RUBY
  spec.name          = 'radical'
  spec.version       = '1.1.0'
  spec.author        = 'Sean Walker'
  spec.email         = 'sean@swlkr.com'

  spec.summary       = 'Rails inspired web framework'
  spec.description   = 'This gem helps you write rails-like web applications'
  spec.homepage      = 'https://github.com/swlkr/radical'
  spec.license       = 'MIT'

  if spec.respond_to?(:metadata)
    spec.metadata['homepage_uri'] = spec.homepage
    spec.metadata['source_code_uri'] = 'https://github.com/swlkr/radical'
    spec.metadata['changelog_uri'] = 'https://github.com/swlkr/radical/blob/main/CHANGELOG.md'
  else
    raise 'RubyGems 2.0 or newer is required to protect against ' \
      'public gem pushes.'
  end

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files = Dir.chdir(File.expand_path(__dir__)) do
    `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(docs|examples|test|Dockerfile|\.rubocop.yml|\.solargraph.yml|\.github)/}) }
  end
  spec.bindir        = 'exe'
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ['lib']

  spec.add_development_dependency 'minitest', '~> 5.14'
  spec.add_development_dependency 'puma', '~> 5.5'
  spec.add_development_dependency 'rack-test', '~> 1.1'
  spec.add_development_dependency 'rake', '~> 13.0'
  spec.add_development_dependency 'sorbet', '~> 0.5'

  spec.add_dependency 'brotli', '~> 0.4'
  spec.add_dependency 'erubi', '~> 1.10'
  spec.add_dependency 'rack', '~> 2.2'
  spec.add_dependency 'rack_csrf', '~> 2.6'
  spec.add_dependency 'rack-flash3', '~> 1.0'
  spec.add_dependency 'sorbet-runtime', '~> 0.5'
  spec.add_dependency 'sqlite3', '~> 1.4'
  spec.add_dependency 'tilt', '~> 2.0'
end
