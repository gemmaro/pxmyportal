# frozen_string_literal: true

require "bundler/gem_tasks"
require "rake/testtask"

Rake::TestTask.new(:test) do |t|
  t.libs << "test"
  t.libs << "lib"
  t.test_files = FileList["test/**/*_test.rb"]
end

default = %i[test]

rubocop = true

begin
  require "rubocop/rake_task"
rescue LoadError
  rubocop = false
end

if rubocop
  RuboCop::RakeTask.new
  default << :rubocop
end

task(default:)
