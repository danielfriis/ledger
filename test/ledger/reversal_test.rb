# frozen_string_literal: true

require "test_helper"

module Ledger
  class ReversalTest < Ledger::Test
    def setup
      super
      @cash = Asset.create!(name: "Cash", code: "1000")
      @revenue = Revenue.create!(name: "Sales", code: "4000")
      @entry = Entry.post!(description: "Cash sale") do |e|
        e.debit @cash, 5_00
        e.credit @revenue, 5_00
      end
    end

    def test_reversal_offsets_the_original
      @entry.reverse!
      assert_equal usd(0), @cash.balance
      assert_equal usd(0), @revenue.balance
    end

    def test_reversal_links_back_to_the_original
      reversal = @entry.reverse!
      assert_equal @entry, reversal.reverses
      assert_equal reversal, @entry.reversal
      assert @entry.reversed?
    end

    def test_reversal_leaves_the_original_intact
      @entry.reverse!
      assert_equal "Cash sale", @entry.reload.description
      assert_equal 2, @entry.lines.count
    end

    def test_trial_balance_stays_zero_after_reversal
      @entry.reverse!
      assert Ledger.trial_balance.zero?
    end
  end
end
