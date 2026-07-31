# frozen_string_literal: true

# A tiny chart of accounts and a couple of opening entries, so a freshly
# prepared database has something to explore:
#
#   bin/rails db:seed
#   bin/rails runner 'puts Ledger::Asset.balance'
#
# Idempotent. Accounts are reference data (find_or_create_by), but entries are
# append-only, so the opening entries are posted only when the books are empty.

cash    = Ledger::Asset.find_or_create_by!(code: "1000")   { |a| a.name = "Cash" }
capital = Ledger::Equity.find_or_create_by!(code: "3000")  { |a| a.name = "Owner's Capital" }
sales   = Ledger::Revenue.find_or_create_by!(code: "4000") { |a| a.name = "Sales" }

if Ledger::Entry.none?
  Ledger::Entry.post!(description: "Owner funds the business") do |entry|
    entry.debit  cash,    100_00
    entry.credit capital, 100_00
  end

  Ledger::Entry.post!(description: "First cash sale") do |entry|
    entry.debit  cash,  5_00
    entry.credit sales, 5_00
  end
end

puts "Seeded #{Ledger::Account.count} accounts and #{Ledger::Entry.count} entries."
puts "Cash balance: #{cash.balance}  |  Trial balance: #{Ledger.trial_balance}"
