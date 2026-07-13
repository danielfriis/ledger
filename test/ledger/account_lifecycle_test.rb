# frozen_string_literal: true

require "test_helper"

module Ledger
  # Accounts are reference data, not events: they stay editable, but the fields
  # the balance is computed from lock once posted, descriptive edits are audited,
  # and retiring an account is a reversible archive rather than a deletion.
  class AccountLifecycleTest < Ledger::Test
    def setup
      super
      @cash = Asset.create!(name: "Cash", code: "1000")
      @revenue = Revenue.create!(name: "Sales", code: "4000")
      @entry = post_sale
    end

    # --- Balance-determining fields lock once posted -----------------------

    def test_currency_cannot_change_once_posted
      assert_raises(ActiveRecord::RecordInvalid) { @cash.update!(currency: "EUR") }
    end

    def test_contra_cannot_change_once_posted
      assert_raises(ActiveRecord::RecordInvalid) { @cash.update!(contra: true) }
    end

    def test_type_cannot_change_once_posted
      assert_raises(ActiveRecord::RecordInvalid) { @cash.update!(type: "Ledger::Liability") }
    end

    def test_balance_determining_fields_are_editable_before_posting
      account = Asset.create!(name: "Scratch", currency: "USD")
      account.update!(currency: "EUR", contra: true)
      assert_equal "EUR", account.reload.currency
      assert account.contra?
    end

    # --- Descriptive edits are audited -------------------------------------

    def test_renaming_is_recorded
      @cash.update!(name: "Cash on hand")
      edit = @cash.edits.last
      assert_equal "name", edit.field
      assert_equal "Cash", edit.old_value
      assert_equal "Cash on hand", edit.new_value
    end

    def test_recoding_is_recorded
      @cash.update!(code: "1001")
      edit = @cash.edits.last
      assert_equal "code", edit.field
      assert_equal "1000", edit.old_value
      assert_equal "1001", edit.new_value
    end

    def test_archiving_is_not_recorded_as_a_descriptive_edit
      before = @cash.edits.count
      @cash.archive!
      assert_equal before, @cash.edits.count
    end

    def test_edits_are_append_only
      @cash.update!(name: "Renamed")
      assert_raises(ActiveRecord::ReadOnlyRecord) { @cash.edits.last.update!(new_value: "Tampered") }
      assert_raises(Ledger::RecordImmutable) { @cash.edits.last.destroy }
    end

    # --- Archiving ---------------------------------------------------------

    def test_archive_sets_the_timestamp_and_scopes
      @cash.archive!
      assert @cash.archived?
      assert_includes Account.archived, @cash
      refute_includes Account.active, @cash
    end

    def test_unarchive_restores_an_active_account
      @cash.archive!
      @cash.unarchive!
      refute @cash.archived?
      assert_includes Account.active, @cash
    end

    def test_archived_account_refuses_new_postings
      @cash.archive!
      error = assert_raises(ActiveRecord::RecordInvalid) { post_sale }
      assert_match(/archived/, error.message)
    end

    def test_an_entry_touching_an_archived_account_can_still_be_reversed
      @cash.archive!
      reversal = @entry.reverse!
      assert reversal.persisted?
      assert_equal usd(0), @cash.balance
    end

    private

    def post_sale
      Entry.post!(description: "Cash sale") do |e|
        e.debit @cash, 5_00
        e.credit @revenue, 5_00
      end
    end
  end
end
