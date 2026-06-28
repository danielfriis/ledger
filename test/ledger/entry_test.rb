# frozen_string_literal: true

require "test_helper"

module Ledger
  class EntryTest < Ledger::Test
    def setup
      super
      @cash = Asset.create!(name: "Cash", code: "1000")
      @revenue = Revenue.create!(name: "Sales", code: "4000")
    end

    def test_posting_a_balanced_entry_persists_it_with_lines
      entry = Entry.post!(description: "Cash sale") do |e|
        e.debit @cash, 5_00
        e.credit @revenue, 5_00
      end

      assert entry.persisted?
      assert_equal 2, entry.lines.count
      assert entry.lines.first.debit?
    end

    def test_unbalanced_entry_is_rejected
      error = assert_raises(ActiveRecord::RecordInvalid) do
        Entry.post!(description: "Lopsided") do |e|
          e.debit @cash, 5_00
          e.credit @revenue, 4_00
        end
      end
      assert_match "balance", error.message
    end

    def test_entry_needs_at_least_two_lines
      assert_raises(ActiveRecord::RecordInvalid) do
        Entry.post!(description: "Dangling") { |e| e.debit @cash, 1_00 }
      end
    end

    def test_occurred_at_defaults_to_now
      entry = Entry.post!(description: "Now") do |e|
        e.debit @cash, 1_00
        e.credit @revenue, 1_00
      end
      assert_kind_of Time, entry.occurred_at
    end

    def test_amount_reports_the_value_moved
      entry = Entry.post!(description: "Sale") do |e|
        e.debit @cash, 5_00
        e.credit @revenue, 5_00
      end
      assert_equal usd(5_00), entry.amount
    end

    def test_accepts_money_as_well_as_cents
      entry = Entry.post!(description: "Sale") do |e|
        e.debit @cash, Money.new(2_50, "USD")
        e.credit @revenue, Money.new(2_50, "USD")
      end
      assert_equal usd(2_50), entry.amount
    end
  end
end
