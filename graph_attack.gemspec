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

  spec.files = `git ls-files -z`.split("\x0").reject do |f|
    f.match(%r{^(test|spec|features)/})
  end
  spec.bindir = 'exe'
  spec.executables = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ['lib']

  spec.add_development_dependency 'bundler', '~> 1.16'
  spec.add_development_dependency 'rake', '~> 10.0'
  spec.add_development_dependency 'rspec', '~> 3.0'
  spec.add_development_dependency 'rubocop', '~> 0.55'
end
