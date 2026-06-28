# frozen_string_literal: true

require "test_helper"

module Ledger
  class MoneyTest < Ledger::Test
    def test_exact_decimal_value
      assert_equal BigDecimal("12.34"), Money.new(1234, "USD").amount
    end

    def test_addition_and_subtraction
      assert_equal Money.new(300, "USD"), Money.new(100, "USD") + Money.new(200, "USD")
      assert_equal Money.new(100, "USD"), Money.new(300, "USD") - Money.new(200, "USD")
    end

    def test_mixing_currencies_raises
      assert_raises(ArgumentError) { Money.new(1, "USD") + Money.new(1, "EUR") }
    end

    def test_equality_considers_currency
      assert_equal Money.new(100, "USD"), Money.new(100, "USD")
      refute_equal Money.new(100, "USD"), Money.new(100, "EUR")
    end

    def test_zero_decimal_currency_has_no_subunit
      assert_equal "500 JPY", Money.new(500, "JPY").to_s
      assert_equal "5.00 USD", Money.new(500, "USD").to_s
    end
  end
end
