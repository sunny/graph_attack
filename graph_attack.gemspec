# frozen_string_literal: true

lib = File.expand_path('lib', __dir__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'graph_attack/version'

Gem::Specification.new do |spec|
  spec.name = 'graph_attack'
  spec.version = GraphAttack::VERSION
  spec.authors = ['Fanny Cheung', 'Sunny Ripert']
  spec.email = ['fanny@ynote.hk', 'sunny@sunfox.org']

  spec.summary = 'GraphQL analyser for blocking & throttling'
  spec.description = 'GraphQL analyser for blocking & throttling'
  spec.homepage = 'https://github.com/sunny/graph_attack'

  spec.metadata['rubygems_mfa_required'] = 'true'

  spec.files = `git ls-files -z`.split("\x0").reject do |f|
    f.match(%r{^(test|spec|features)/})
  end
  spec.bindir = 'exe'
  spec.executables = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ['lib']

  spec.required_ruby_version = '>= 2.5.7'

  # This gem is an analyser for the GraphQL ruby gem.
  spec.add_dependency 'graphql', '>= 1.7.9'

  # A Redis-backed rate limiter.
  spec.add_dependency 'ratelimit', '>= 1.0.4'

  # Loads local dependencies.
  spec.add_development_dependency 'bundler', '~> 2.0'

  # Development tasks runner.
  spec.add_development_dependency 'rake', '~> 13.0'

  # Testing framework.
  spec.add_development_dependency 'rspec', '~> 3.0'

  # CircleCI dependency to store spec results.
  spec.add_development_dependency 'rspec_junit_formatter', '~> 0.3'

  # Ruby code linter.
  spec.add_development_dependency 'rubocop', '~> 1.50.0'

  # RSpec extension for RuboCop.
  spec.add_development_dependency 'rubocop-rspec', '~> 2.19.0'

  # Rake extension for RuboCop
  spec.add_development_dependency 'rubocop-rake', '~> 0.6.0'
end
