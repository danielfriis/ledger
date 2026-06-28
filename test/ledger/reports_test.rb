# frozen_string_literal: true

require "test_helper"

module Ledger
  class ReportsTest < Ledger::Test
    def setup
      super
      @cash = Asset.create!(name: "Cash", code: "1000")
      @capital = Equity.create!(name: "Capital", code: "3000")
      @revenue = Revenue.create!(name: "Sales", code: "4000")
      @rent = Expense.create!(name: "Rent", code: "5000")

      Entry.post!(description: "Owner funds the business") do |e|
        e.debit @cash, 100_00
        e.credit @capital, 100_00
      end
      Entry.post!(description: "Sale") do |e|
        e.debit @cash, 40_00
        e.credit @revenue, 40_00
      end
      Entry.post!(description: "Pay rent") do |e|
        e.debit @rent, 15_00
        e.credit @cash, 15_00
      end
    end

    def test_income_statement_nets_revenue_against_expenses
      statement = IncomeStatement.new
      assert_equal usd(40_00), statement.total_revenue
      assert_equal usd(15_00), statement.total_expenses
      assert_equal usd(25_00), statement.net_income
    end

    def test_balance_sheet_balances
      sheet = BalanceSheet.new
      assert_equal usd(125_00), sheet.total_assets # 100 + 40 - 15
      assert_equal usd(100_00), sheet.total_equity
      assert_equal usd(25_00), sheet.retained_earnings
      assert sheet.balanced?
    end

    def test_balance_sheet_lists_positions
      sheet = BalanceSheet.new
      assert_equal [ "Cash" ], sheet.assets.map { |p| p.account.name }
      assert_equal usd(125_00), sheet.assets.first.balance
    end
  end
end
