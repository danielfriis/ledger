# frozen_string_literal: true

# Accounts are reference data, not events, so unlike entries they stay editable
# over their life. This adds the two things that lifecycle needs: a soft-archive
# timestamp (retire without deleting) and an append-only log of the edits we do
# allow, so a rename or re-code is always traceable.
class AddAccountLifecycle < ActiveRecord::Migration[7.1]
  def change
    add_column :ledger_accounts, :archived_at, :datetime
    add_index :ledger_accounts, :archived_at

    create_table :ledger_account_edits do |t|
      t.references :account, null: false, foreign_key: { to_table: :ledger_accounts }
      t.string :field, null: false
      t.string :old_value
      t.string :new_value
      t.datetime :created_at, null: false
    end
  end
end
