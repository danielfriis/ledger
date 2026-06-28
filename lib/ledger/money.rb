# frozen_string_literal: true

require "bigdecimal"

module Ledger
  # A minimal money value object backed by integer minor units (cents).
  #
  # Owning this rather than depending on the money gem keeps Ledger
  # dependency-light. It is deliberately small: arithmetic between different
  # currencies raises rather than silently converting.
  class Money
    include Comparable

    # Currencies whose minor unit is the whole unit (no cents).
    ZERO_DECIMAL_CURRENCIES = %w[JPY KRW VND CLP ISK XOF XAF].freeze

    attr_reader :cents, :currency

    def self.zero(currency = Ledger.default_currency)
      new(0, currency)
    end

    def initialize(cents, currency = Ledger.default_currency)
      @cents = Integer(cents)
      @currency = currency.to_s.upcase
    end

    def +(other)
      combine(other, :+)
    end

    def -(other)
      combine(other, :-)
    end

    def -@
      self.class.new(-cents, currency)
    end

    def zero? = cents.zero?
    def positive? = cents.positive?
    def negative? = cents.negative?

    # 1 for zero-decimal currencies, 100 otherwise.
    def subunit
      ZERO_DECIMAL_CURRENCIES.include?(currency) ? 1 : 100
    end

    # The exact decimal value (e.g. 1234 cents => 12.34).
    def amount
      BigDecimal(cents) / subunit
    end

    def <=>(other)
      return nil unless other.is_a?(Money) && currency == other.currency

      cents <=> other.cents
    end

    def ==(other)
      other.is_a?(Money) && cents == other.cents && currency == other.currency
    end
    alias eql? ==

    def hash
      [ cents, currency ].hash
    end

    def to_s
      return "#{cents} #{currency}" if subunit == 1

      format("%.2f %s", cents.fdiv(subunit), currency)
    end

    def inspect
      "#<Ledger::Money #{self}>"
    end

    private

    def combine(other, operator)
      unless other.is_a?(Money) && other.currency == currency
        raise ArgumentError, "cannot #{operator} money of differing currencies"
      end

      self.class.new(cents.public_send(operator, other.cents), currency)
    end
  end
end
