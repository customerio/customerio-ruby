# -*- encoding: utf-8 -*-
require File.expand_path('../lib/customerio/version', __FILE__)

Gem::Specification.new do |gem|
  gem.authors       = ["John Allison"]
  gem.email         = ["john@customer.io"]
  gem.description   = "A ruby client for the Customer.io event API."
  gem.summary       = "A ruby client for the Customer.io event API."
  gem.homepage      = "http://customer.io"

  gem.files         = `git ls-files`.split($\)
  gem.executables   = gem.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.name          = "customerio"
  gem.require_paths = ["lib"]
  gem.version       = Customerio::VERSION

  gem.add_dependency('multi_json', "~> 1.0")

  gem.add_development_dependency('rake')
  gem.add_development_dependency('rspec')
  gem.add_development_dependency('webmock')
  gem.add_development_dependency('addressable', '~> 2.3.6')
  gem.add_development_dependency('json')
end
