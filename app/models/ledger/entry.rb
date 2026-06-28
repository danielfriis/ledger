# frozen_string_literal: true

module Ledger
  # A journal entry: one balanced transaction made of two or more lines whose
  # signed amounts sum to zero. Entries are append-only — once posted they can
  # never be changed or deleted. To undo one, post its #reverse!.
  #
  #   Ledger::Entry.post!(description: "Cash sale") do |e|
  #     e.debit  cash,    5_00
  #     e.credit revenue, 5_00
  #   end
  class Entry < ActiveRecord::Base
    include Ledger::Immutable

    # What this entry was recorded for (an invoice, a payment, ...). Optional.
    belongs_to :source, polymorphic: true, optional: true

    # If this entry reverses another, the original is its +reverses+; the
    # original reaches back to this one through +reversal+.
    belongs_to :reverses, class_name: "Ledger::Entry", foreign_key: :reversed_entry_id, optional: true
    has_one :reversal, class_name: "Ledger::Entry", foreign_key: :reversed_entry_id, inverse_of: :reverses

    has_many :lines, class_name: "Ledger::Line", inverse_of: :entry, autosave: true, dependent: :destroy

    validates :description, presence: true
    validates :occurred_at, presence: true
    validate :at_least_two_lines
    validate :single_currency
    validate :must_balance

    before_validation { self.occurred_at ||= Time.current }

    # True only while this entry is being posted, so its lines know they are
    # being attached as part of the original transaction rather than grafted
    # onto an already-posted entry. See Line#refuse_to_join_posted_entry.
    attr_reader :posting
    alias_method :posting?, :posting

    # Build and post an entry in one call.
    def self.post!(attributes = {})
      entry = new(attributes)
      yield entry if block_given?
      entry.post!
    end

    # Add a debit line for +amount+ (Integer cents or a Ledger::Money).
    def debit(account, amount)
      build_line(account, cents(amount))
    end

    # Add a credit line for +amount+ (Integer cents or a Ledger::Money).
    def credit(account, amount)
      build_line(account, -cents(amount))
    end

    # Validate, write, and freeze the entry and its lines.
    def post!
      @posting = true
      save!
      self
    ensure
      @posting = false
    end

    # Post a new entry that exactly offsets this one, leaving the original
    # untouched. This is how corrections are made in an append-only ledger.
    def reverse!(occurred_at: nil, description: nil)
      raise Ledger::Error, "only a posted entry can be reversed" unless persisted?

      reversal = self.class.new(
        description: description || "Reversal of: #{self.description}",
        occurred_at: occurred_at || Time.current,
        reverses: self,
        source: source
      )
      lines.each do |line|
        reversal.lines.build(account: line.account, amount_cents: -line.amount_cents, currency: line.currency)
      end
      reversal.post!
    end

    def reversed?
      reversal.present?
    end

    # The total value moved (debits and credits are equal, so either side).
    def amount
      Money.new(lines.select(&:debit?).sum(&:amount_cents), currency)
    end

    def currency
      lines.first&.currency || Ledger.default_currency
    end

    private

    def build_line(account, signed_cents)
      lines.build(account: account, amount_cents: signed_cents, currency: account.currency)
    end

    def cents(amount)
      case amount
      when Ledger::Money then amount.cents
      when Integer then amount
      else raise ArgumentError, "amount must be Integer cents or a Ledger::Money, got #{amount.class}"
      end
    end

    def at_least_two_lines
      errors.add(:base, "must have at least two lines") if lines.size < 2
    end

    def single_currency
      errors.add(:base, "every line must share one currency") if lines.map(&:currency).compact.uniq.size > 1
    end

    def must_balance
      errors.add(:base, "debits and credits must balance") unless lines.sum(&:amount_cents).zero?
    end
  end
end
