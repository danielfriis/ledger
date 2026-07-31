# frozen_string_literal: true

ENV["RAILS_ENV"] ||= "test"
require_relative "../config/environment"
require "rails/test_help"

module Ledger
  # Shared base for the bookkeeping tests. Each test runs inside a transaction
  # that rolls back afterward, so every test opens on empty books — the rollback
  # is a raw SQL ROLLBACK, so it slips past the append-only guards on its own.
  class Test < ActiveSupport::TestCase
    private

    def usd(cents) = Ledger::Money.new(cents, "USD")
  end
end
