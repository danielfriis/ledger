# frozen_string_literal: true

module Ledger
  # Makes a record append-only once it has been written.
  #
  # ActiveRecord refuses to UPDATE a +readonly?+ record, so reporting +true+
  # the moment a record is persisted blocks every later change while still
  # allowing the initial INSERT (a brand-new record is not yet persisted).
  # Deletion is guarded separately because +destroy+ ignores +readonly?+.
  module Immutable
    extend ActiveSupport::Concern

    included do
      before_destroy :raise_immutable
    end

    def readonly?
      persisted? || super
    end

    private

    def raise_immutable
      raise Ledger::RecordImmutable, "#{self.class.name} records are append-only and cannot be deleted"
    end
  end
end
