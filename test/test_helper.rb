# frozen_string_literal: true

require "minitest/autorun"
require "active_record"

ActiveRecord::Base.establish_connection(adapter: "sqlite3", database: ":memory:")

require "ledger"

ActiveRecord::Migration.suppress_messages do
  require_relative "../db/migrate/20260628000001_create_ledger_tables"
  CreateLedgerTables.migrate(:up)
  require_relative "../db/migrate/20260702000001_add_account_lifecycle"
  AddAccountLifecycle.migrate(:up)
end

module Ledger
  # Shared base: fresh books before every test. delete_all issues raw DELETEs,
  # bypassing the append-only guards (which is exactly what we want for teardown).
  class Test < Minitest::Test
    def setup
      Ledger::Line.delete_all
      Ledger::Entry.delete_all
      Ledger::AccountEdit.delete_all
      Ledger::Account.delete_all
    end

    private

    def usd(cents) = Ledger::Money.new(cents, "USD")
  end
end
