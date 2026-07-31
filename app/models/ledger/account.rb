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
  class Account < ApplicationRecord
    # Set by each subclass to :debit or :credit.
    class_attribute :normal_balance, instance_writer: false

    # Fields that decide how this account's balance is computed. Once the
    # account carries postings they are frozen: changing +type+, +contra+, or
    # +currency+ would silently rewrite every historical balance — the same
    # reason posted entries are immutable. Descriptive fields stay editable.
    BALANCE_DETERMINING = %w[type contra currency].freeze

    # Descriptive fields that may be edited over the account's life; each change
    # is recorded in the audit trail so it stays traceable.
    DESCRIPTIVE = %w[name code].freeze

    has_many :lines, class_name: "Ledger::Line", dependent: :restrict_with_error
    has_many :entries, -> { distinct }, through: :lines, class_name: "Ledger::Entry"

    # The append-only audit trail of descriptive edits. Edits themselves can't
    # be altered, but they die with their account: only an unused account can be
    # deleted (postings restrict it), and +delete_all+'s raw SQL is what lets the
    # cascade past the immutability guard.
    has_many :edits, class_name: "Ledger::AccountEdit", dependent: :delete_all

    # An archived account is retired: it keeps its balance and history but
    # refuses new postings. Archiving is reversible; it is not deletion.
    scope :active, -> { where(archived_at: nil) }
    scope :archived, -> { where.not(archived_at: nil) }

    normalizes :currency, with: ->(currency) { currency.upcase }

    validates :type, presence: true
    validates :name, presence: true
    validates :code, uniqueness: true, allow_nil: true
    validate :balance_determining_fields_stay_put, on: :update

    before_validation { self.currency ||= Ledger.default_currency }

    # Log edits to descriptive fields after they are written.
    after_update :log_descriptive_edits

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

    def archived? = archived_at.present?

    # Retire the account without deleting it. Archiving is reversible and blocks
    # new postings (see Ledger::Line); existing balances and history are kept.
    def archive!
      update!(archived_at: Time.current) unless archived?
    end

    def unarchive!
      update!(archived_at: nil)
    end

    private

    def direction_sign
      contra? ? -self.class.type_sign : self.class.type_sign
    end

    # Once an account has postings, refuse edits to the fields the balance is
    # computed from — allowing them would retroactively rewrite history.
    def balance_determining_fields_stay_put
      locked = changed & BALANCE_DETERMINING
      return if locked.empty? || !lines.exists?

      locked.each { |field| errors.add(field, "cannot change once the account has postings") }
    end

    # Record each descriptive edit as its own append-only audit row.
    def log_descriptive_edits
      saved_changes.slice(*DESCRIPTIVE).each do |field, (old_value, new_value)|
        edits.create!(field:, old_value:, new_value:)
      end
    end
  end
end
