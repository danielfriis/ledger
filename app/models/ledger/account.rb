# frozen_string_literal: true

module Ledger
  # An account is a ledger you post against. It is never instantiated directly:
  # every account is one of the five standard types, which differ only in their
  # +normal_balance+ — the side (debit or credit) on which a positive balance
  # naturally falls.
  #
  #   TYPE       NORMAL BALANCE   WHAT IT TRACKS
  #   Asset      debit            resources the entity owns
  #   Liability  credit           what the entity owes
  #   Equity     credit           owners' residual interest
  #   Revenue    credit           income earned
  #   Expense    debit            costs incurred
  #
  # A +contra+ account flips its normal side — e.g. "Accumulated Depreciation"
  # is a contra-asset that carries a credit balance and nets against assets.
  class Account < ActiveRecord::Base
    # Set by each subclass to :debit or :credit.
    class_attribute :normal_balance, instance_writer: false

    has_many :lines, class_name: "Ledger::Line", dependent: :restrict_with_error
    has_many :entries, -> { distinct }, through: :lines, class_name: "Ledger::Entry"

    normalizes :currency, with: ->(currency) { currency.upcase }

    validates :type, presence: true
    validates :name, presence: true
    validates :code, uniqueness: true, allow_nil: true

    before_validation { self.currency ||= Ledger.default_currency }

    # The balance of this single account, optionally within a period.
    #
    #   account.balance                       # all time
    #   account.balance(as_of: Date.today)    # cumulative up to a date
    #   account.balance(from: a, to: b)       # activity within a window
    def balance(as_of: nil, from: nil, to: nil)
      cents = direction_sign * lines.in_period(as_of:, from:, to:).sum(:amount_cents)
      Money.new(cents, currency)
    end

    # The combined balance of every account of this type. Contra accounts net
    # out automatically because the signed amounts already point the right way.
    def self.balance(as_of: nil, from: nil, to: nil)
      raise NoMethodError, "balance is only defined on Account subclasses" if self == Ledger::Account

      cents = type_sign * Line.where(account: all).in_period(as_of:, from:, to:).sum(:amount_cents)
      Money.new(cents, Ledger.default_currency)
    end

    # +1 for debit-normal types, -1 for credit-normal — the factor that turns a
    # signed line total (debit positive, credit negative) into a reported balance.
    def self.type_sign
      normal_balance == :debit ? 1 : -1
    end

    private

    def direction_sign
      contra? ? -self.class.type_sign : self.class.type_sign
    end
  end
end
