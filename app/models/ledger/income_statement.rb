# frozen_string_literal: true

module Ledger
  # Revenue earned and expenses incurred over a period, and the resulting net
  # income. Omitting +from+/+to+ reports over all time.
  class IncomeStatement
    Position = Struct.new(:account, :balance)

    attr_reader :from, :to

    def initialize(from: nil, to: nil)
      @from = from
      @to = to
    end

    def revenues = positions(Revenue)
    def expenses = positions(Expense)

    def total_revenue = Revenue.balance(from:, to:)
    def total_expenses = Expense.balance(from:, to:)

    def net_income
      total_revenue - total_expenses
    end

    private

    def positions(type)
      type.order(:name).map { |account| Position.new(account, account.balance(from:, to:)) }
    end
  end
end
