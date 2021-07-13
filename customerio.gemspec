# -*- encoding: utf-8 -*-
require File.expand_path('../lib/customerio/version', __FILE__)

Gem::Specification.new do |gem|
  gem.authors       = ["John Allison"]
  gem.email         = ["john@customer.io"]
  gem.description   = "A ruby client for the Customer.io event API."
  gem.summary       = "A ruby client for the Customer.io event API."
  gem.homepage      = "http://customer.io"
  gem.license       = "MIT"

  gem.files         = `git ls-files`.split($\)
  gem.executables   = gem.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.name          = "customerio"
  gem.require_paths = ["lib"]
  gem.version       = Customerio::VERSION

  gem.add_dependency('multi_json', "~> 1.0")
  gem.add_dependency('addressable', '~> 2.8.0')

  gem.add_development_dependency('rake', '~> 10.5')
  gem.add_development_dependency('rspec', '3.3.0')
  gem.add_development_dependency('webmock', '3.6.0')
  gem.add_development_dependency('json')
end
