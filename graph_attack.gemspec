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
end
