# frozen_string_literal: true

module Ledger
  # A single posting within an entry. The +amount_cents+ is *signed*: a debit
  # is positive, a credit is negative. That one convention is what makes a
  # balanced entry "sums to zero" and an account balance a single SQL SUM.
  #
  # Lines are append-only — see Ledger::Immutable.
  class Line < ActiveRecord::Base
    include Ledger::Immutable

    belongs_to :entry, class_name: "Ledger::Entry", inverse_of: :lines
    belongs_to :account, class_name: "Ledger::Account"

    normalizes :currency, with: ->(currency) { currency.upcase }

    validates :amount_cents, numericality: { only_integer: true, other_than: 0 }
    validates :currency, presence: true
    validate :account_accepts_postings, on: :create

    before_validation { self.currency ||= account&.currency || Ledger.default_currency }
    before_create :refuse_to_join_posted_entry

    # Restrict to lines whose entry falls in a period. Bounds may be Date or
    # Time; a Date upper bound includes the whole day.
    scope :in_period, ->(as_of: nil, from: nil, to: nil) do
      next all unless as_of || from || to

      relation = joins(:entry)
      relation = relation.where(ledger_entries: { occurred_at: ..upper_bound(as_of) }) if as_of
      relation = relation.where(ledger_entries: { occurred_at: lower_bound(from).. }) if from
      relation = relation.where(ledger_entries: { occurred_at: ..upper_bound(to) }) if to
      relation
    end

    def self.upper_bound(value)
      value.is_a?(Date) ? value.end_of_day : value
    end

    def self.lower_bound(value)
      value.is_a?(Date) ? value.beginning_of_day : value
    end

    def debit? = amount_cents.positive?
    def credit? = amount_cents.negative?
    def direction = debit? ? :debit : :credit

    # The magnitude as money (always positive); use #direction for the side.
    def amount
      Money.new(amount_cents.abs, currency)
    end

    private

    # New activity may not be posted to an archived account. A reversal is a
    # correction of history rather than new activity, so it is always allowed —
    # otherwise a mistaken entry could never be undone once its account was
    # retired.
    def account_accepts_postings
      return if entry&.reverses?
      return unless account&.archived?

      errors.add(:account, "is archived and cannot receive new postings")
    end

    # Allowed only while the entry is being posted for the first time. Once an
    # entry is persisted and no longer posting, no new lines may be attached.
    def refuse_to_join_posted_entry
      return if entry.nil? || entry.posting? || !entry.persisted?

      raise Ledger::RecordImmutable, "cannot add a line to a posted entry"
    end
  end
end
