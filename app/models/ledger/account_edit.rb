# frozen_string_literal: true

module Ledger
  # An append-only record of a single edit to an account's descriptive fields.
  # Balance-determining fields (type, contra, currency) can never change once an
  # account is posted to, so they never appear here — only the safe, cosmetic
  # edits (name, code) are logged, giving a rename or re-code a traceable history
  # without touching the account itself.
  class AccountEdit < ApplicationRecord
    include Ledger::Immutable

    belongs_to :account, class_name: "Ledger::Account"

    validates :field, presence: true
  end
end
