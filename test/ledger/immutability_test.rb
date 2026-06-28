# frozen_string_literal: true

require "test_helper"

module Ledger
  class ImmutabilityTest < Ledger::Test
    def setup
      super
      @cash = Asset.create!(name: "Cash", code: "1000")
      @revenue = Revenue.create!(name: "Sales", code: "4000")
      @entry = Entry.post!(description: "Cash sale") do |e|
        e.debit @cash, 5_00
        e.credit @revenue, 5_00
      end
    end

    def test_posted_entry_cannot_be_updated
      assert_raises(ActiveRecord::ReadOnlyRecord) do
        @entry.update!(description: "Tampered")
      end
    end

    def test_posted_entry_cannot_be_destroyed
      assert_raises(Ledger::RecordImmutable) { @entry.destroy }
      assert Entry.exists?(@entry.id)
    end

    def test_posted_line_cannot_be_updated
      assert_raises(ActiveRecord::ReadOnlyRecord) do
        @entry.lines.first.update!(amount_cents: 9_99)
      end
    end

    def test_posted_line_cannot_be_destroyed
      assert_raises(Ledger::RecordImmutable) { @entry.lines.first.destroy }
    end

    def test_cannot_graft_a_line_onto_a_posted_entry
      assert_raises(Ledger::RecordImmutable) do
        @entry.lines.create!(account: @cash, amount_cents: 1_00)
      end
    end

    def test_accounts_remain_editable
      @cash.update!(name: "Cash on hand")
      assert_equal "Cash on hand", @cash.reload.name
    end
  end
end
