# frozen_string_literal: true

require_relative "lib/customerio/version"

Gem::Specification.new do |gem|
  gem.authors = ["John Allison"]
  gem.email = ["john@customer.io"]
  gem.description = "A ruby client for the Customer.io event API."
  gem.summary = "A ruby client for the Customer.io event API."
  gem.homepage = "https://customer.io"
  gem.license = "MIT"

  gem.files = Dir["CHANGELOG.markdown", "LICENSE", "README.md", "lib/**/*.rb"]
  gem.executables = gem.files.grep(%r{\Abin/}).map { |file| File.basename(file) }
  gem.name = "customerio"
  gem.require_paths = ["lib"]
  gem.required_ruby_version = ">= 3.3"
  gem.version = Customerio::VERSION

  gem.metadata = {
    "bug_tracker_uri" => "https://github.com/customerio/customerio-ruby/issues",
    "changelog_uri" => "https://github.com/customerio/customerio-ruby/blob/main/CHANGELOG.markdown",
    "homepage_uri" => "https://customer.io",
    "rubygems_mfa_required" => "true",
    "source_code_uri" => "https://github.com/customerio/customerio-ruby"
  }

  gem.add_dependency "addressable", "~> 2.9"
  gem.add_dependency "base64", "~> 0.3"
end
