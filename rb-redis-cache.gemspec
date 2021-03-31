# frozen_string_literal: true

require_relative 'lib/cache/version'

Gem::Specification.new do |spec|
  spec.name = 'rb-redis-cache'
  spec.version = Cache::VERSION
  spec.authors = ['Jérémie Veillet']
  spec.email = ['jveillet@hey.com']
  spec.summary = 'A simple framework-agnostic cache with Redis.'
  spec.description = ''
  spec.homepage = 'https://github.com/jveillet/rb-redis-cache'
  spec.license = 'MIT'
  spec.required_ruby_version = Gem::Requirement.new('>= 2.3.0')
  spec.platform = Gem::Platform::RUBY
  spec.metadata['homepage_uri'] = spec.homepage
  spec.metadata['source_code_uri'] = 'https://github.com/jveillet/rb-redis-cache'

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files = Dir.chdir(File.expand_path(__dir__)) do
    `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  end
  spec.bindir = 'bin'
  spec.executables = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.require_paths = ['lib']

  spec.add_development_dependency 'minitest', '~> 5.0'
  spec.add_development_dependency 'mock_redis', '~> 0.27.3'
  spec.add_development_dependency 'rake', '~> 12.0'
  spec.add_development_dependency 'rubocop', '~> 0.91.0'
  spec.add_development_dependency 'rubocop-performance', '~> 1.6', '>= 1.6.1'
  spec.add_development_dependency 'yard', '~> 0.9.26'

  spec.add_dependency 'connection_pool', '~> 2.2', '>= 2.2.3'
  spec.add_dependency 'redis', '~> 4.2', '>= 4.2.5'
end
