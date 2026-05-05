# frozen_string_literal: true

require "bundler/gem_tasks"
require "rubocop/rake_task"
require "rspec/core"
require "rspec/core/rake_task"

RSpec::Core::RakeTask.new(:spec)

RuboCop::RakeTask.new(:rubocop) do |task|
  task.patterns = ["Gemfile", "lib/**/*.rb", "customerio.gemspec", "Rakefile"]
end

task lint: :rubocop

task default: %i[spec rubocop]
