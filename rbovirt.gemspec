# -*- encoding: utf-8 -*-
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'ovirt/version'

Gem::Specification.new do |gem|
  gem.name          = "rbovirt"
  gem.version       = OVIRT::VERSION
  gem.license       = "MIT"
  gem.authors       = ['Amos Benari']
  gem.email         = ['abenari@redhat.com']
  gem.homepage      = "http://github.com/abenari/rbovirt"
  gem.summary       = %q{A Ruby client for oVirt REST API}
  gem.description   = <<-EOS
    A Ruby client for oVirt REST API
  EOS

  gem.files         = `git ls-files`.split($/)
  gem.executables   = gem.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.require_paths = ["lib"]

  gem.add_runtime_dependency('nokogiri')
  gem.add_runtime_dependency('rest-client', '> 1.7.0')
  gem.add_development_dependency('shoulda')
  gem.add_development_dependency('rspec-rails', '~> 2.6')
  gem.add_development_dependency('rake')

  gem.required_ruby_version = '>= 1.9.3'

  gem.rdoc_options << '--title' << gem.name << '--main' << 'README.rdoc' << '--line-numbers' << '--inline-source'
  gem.extra_rdoc_files = ['README.rdoc', 'CHANGES.rdoc']
end
