# frozen_string_literal: true

require_relative "lib/ledger/version"

Gem::Specification.new do |spec|
  spec.name = "ledger"
  spec.version = Ledger::VERSION
  spec.authors = [ "Daniel Friis" ]
  spec.email = [ "d@friis.me" ]

  spec.summary = "Immutable double-entry bookkeeping for Rails."
  spec.description = "An append-only, double-entry bookkeeping engine for Rails: " \
                     "typed accounts, balanced journal entries, integer-cent money, " \
                     "reversal-based corrections, and financial reports."
  spec.homepage = "https://github.com/danielfriis/ledger"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 3.2"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = spec.homepage

  spec.files = Dir["{app,config,db,lib}/**/*", "MIT-LICENSE", "Rakefile", "README.md"]

  spec.add_dependency "activerecord", ">= 7.1"
  spec.add_dependency "railties", ">= 7.1"

  spec.add_development_dependency "minitest", "~> 5.0"
  spec.add_development_dependency "rake", "~> 13.0"
  spec.add_development_dependency "rubocop-rails-omakase"
  spec.add_development_dependency "sqlite3", ">= 1.6"
end
