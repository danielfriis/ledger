# frozen_string_literal: true

class CreateLedgerTables < ActiveRecord::Migration[7.1]
  def change
    create_table :ledger_accounts do |t|
      t.string :type, null: false
      t.string :name, null: false
      t.string :code
      t.string :currency, null: false
      t.boolean :contra, null: false, default: false
      t.timestamps
    end
    add_index :ledger_accounts, :type
    add_index :ledger_accounts, :code, unique: true

    create_table :ledger_entries do |t|
      t.string :description, null: false
      t.datetime :occurred_at, null: false
      t.references :source, polymorphic: true
      t.references :reversed_entry, foreign_key: { to_table: :ledger_entries }
      t.timestamps
    end
    add_index :ledger_entries, :occurred_at

    create_table :ledger_lines do |t|
      t.references :entry, null: false, foreign_key: { to_table: :ledger_entries }
      t.references :account, null: false, foreign_key: { to_table: :ledger_accounts }
      t.bigint :amount_cents, null: false
      t.string :currency, null: false
      t.timestamps
    end
    add_index :ledger_lines, %i[account_id entry_id]
  end
end
