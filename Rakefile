# frozen_string_literal: true

require "rake/testtask"

Rake::TestTask.new(:test) do |t|
  t.libs << "test" << "lib"
  t.pattern = "test/**/*_test.rb"
  t.warning = false
end

default_tasks = [ :test ]

begin
  require "rubocop/rake_task"
  RuboCop::RakeTask.new
  default_tasks << :rubocop
rescue LoadError
  # RuboCop is a development dependency; skip the task when it isn't installed.
end

task default: default_tasks
