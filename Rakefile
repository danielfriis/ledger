# Add your own tasks in files placed in lib/tasks ending in .rake,
# for example lib/tasks/capistrano.rake, and they will automatically be available to Rake.

require_relative "config/application"

Rails.application.load_tasks

# Keep bare `rake` meaning "run the tests and the linter", so the one command
# in CLAUDE.md stays green. RuboCop is a development-only dependency, so degrade
# gracefully to just the tests when it isn't installed (e.g. in production).
begin
  require "rubocop/rake_task"
  RuboCop::RakeTask.new
  task default: %i[test rubocop]
rescue LoadError
  task default: %i[test]
end
