# frozen_string_literal: true

require "test_helper"

module Ledger
  class AccountTest < Ledger::Test
    def test_currency_is_normalized_to_uppercase
      account = Asset.create!(name: "Cash", currency: "eur")
      assert_equal "EUR", account.currency
    end

    def test_currency_defaults_to_the_configured_default
      assert_equal "USD", Asset.create!(name: "Cash").currency
    end

    def test_code_must_be_unique
      Asset.create!(name: "Cash", code: "1000")
      assert_raises(ActiveRecord::RecordInvalid) do
        Liability.create!(name: "Other", code: "1000")
      end
    end

    def test_base_account_class_has_no_balance
      assert_raises(NoMethodError) { Account.balance }
    end
  end
end
