# frozen_string_literal: true

# Loads the ActiveRecord models when running outside Rails (e.g. in tests or
# a plain Ruby app). Inside a Rails app the engine lets Zeitwerk autoload
# these from app/models, so this file must not be required there.
models = File.expand_path("../../app/models/ledger", __dir__)

%w[
  account asset liability equity revenue expense
  entry line
  balance_sheet income_statement
].each do |model|
  require File.join(models, "#{model}.rb")
end
