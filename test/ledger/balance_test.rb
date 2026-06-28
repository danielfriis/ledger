# frozen_string_literal: true

require "test_helper"

module Ledger
  class BalanceTest < Ledger::Test
    def setup
      super
      @cash = Asset.create!(name: "Cash", code: "1000")
      @loan = Liability.create!(name: "Loan", code: "2000")
      @revenue = Revenue.create!(name: "Sales", code: "4000")
    end

    def post(description, occurred_at: nil)
      Entry.post!(description:, occurred_at:) { |e| yield e }
    end

    def test_debit_raises_an_asset_balance
      post("Funding") { |e| e.debit @cash, 10_00; e.credit @loan, 10_00 }
      assert_equal usd(10_00), @cash.balance
      assert_equal usd(10_00), @loan.balance
    end

    def test_balances_net_across_entries
      post("Funding") { |e| e.debit @cash, 10_00; e.credit @loan, 10_00 }
      post("Repay") { |e| e.debit @loan, 4_00; e.credit @cash, 4_00 }
      assert_equal usd(6_00), @cash.balance
      assert_equal usd(6_00), @loan.balance
    end

    def test_class_level_balance_aggregates_the_type
      cash2 = Asset.create!(name: "Bank", code: "1010")
      post("A") { |e| e.debit @cash, 3_00; e.credit @revenue, 3_00 }
      post("B") { |e| e.debit cash2, 7_00; e.credit @revenue, 7_00 }
      assert_equal usd(10_00), Asset.balance
      assert_equal usd(10_00), Revenue.balance
    end

    def test_period_filtering
      post("Old", occurred_at: Time.utc(2026, 1, 1)) { |e| e.debit @cash, 5_00; e.credit @revenue, 5_00 }
      post("New", occurred_at: Time.utc(2026, 6, 1)) { |e| e.debit @cash, 8_00; e.credit @revenue, 8_00 }

      assert_equal usd(5_00), @cash.balance(as_of: Date.new(2026, 3, 1))
      assert_equal usd(8_00), @cash.balance(from: Date.new(2026, 4, 1), to: Date.new(2026, 12, 31))
      assert_equal usd(13_00), @cash.balance
    end

    def test_contra_account_nets_against_its_type
      gross = Asset.create!(name: "Equipment", code: "1500")
      depreciation = Asset.create!(name: "Accumulated Depreciation", code: "1510", contra: true)

      post("Buy") { |e| e.debit gross, 100_00; e.credit @cash, 100_00 }
      post("Depreciate") { |e| e.debit @revenue, 30_00; e.credit depreciation, 30_00 }

      assert_equal usd(30_00), depreciation.balance # contra carries a positive own balance
      # Equipment 100 - depreciation 30 + cash -100 = -30 net across asset type
      assert_equal usd(-30_00), Asset.balance
    end

    def test_trial_balance_is_always_zero
      post("A") { |e| e.debit @cash, 3_00; e.credit @revenue, 3_00 }
      post("B") { |e| e.debit @cash, 7_00; e.credit @loan, 7_00 }
      assert Ledger.trial_balance.zero?
    end
  end
end
