# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.1].define(version: 2026_07_02_000001) do
  create_table "ledger_account_edits", force: :cascade do |t|
    t.integer "account_id", null: false
    t.datetime "created_at", null: false
    t.string "field", null: false
    t.string "new_value"
    t.string "old_value"
    t.index ["account_id"], name: "index_ledger_account_edits_on_account_id"
  end

  create_table "ledger_accounts", force: :cascade do |t|
    t.datetime "archived_at"
    t.string "code"
    t.boolean "contra", default: false, null: false
    t.datetime "created_at", null: false
    t.string "currency", null: false
    t.string "name", null: false
    t.string "type", null: false
    t.datetime "updated_at", null: false
    t.index ["archived_at"], name: "index_ledger_accounts_on_archived_at"
    t.index ["code"], name: "index_ledger_accounts_on_code", unique: true
    t.index ["type"], name: "index_ledger_accounts_on_type"
  end

  create_table "ledger_entries", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "description", null: false
    t.datetime "occurred_at", null: false
    t.integer "reversed_entry_id"
    t.integer "source_id"
    t.string "source_type"
    t.datetime "updated_at", null: false
    t.index ["occurred_at"], name: "index_ledger_entries_on_occurred_at"
    t.index ["reversed_entry_id"], name: "index_ledger_entries_on_reversed_entry_id"
    t.index ["source_type", "source_id"], name: "index_ledger_entries_on_source"
  end

  create_table "ledger_lines", force: :cascade do |t|
    t.integer "account_id", null: false
    t.bigint "amount_cents", null: false
    t.datetime "created_at", null: false
    t.string "currency", null: false
    t.integer "entry_id", null: false
    t.datetime "updated_at", null: false
    t.index ["account_id", "entry_id"], name: "index_ledger_lines_on_account_id_and_entry_id"
    t.index ["account_id"], name: "index_ledger_lines_on_account_id"
    t.index ["entry_id"], name: "index_ledger_lines_on_entry_id"
  end

  add_foreign_key "ledger_account_edits", "ledger_accounts", column: "account_id"
  add_foreign_key "ledger_entries", "ledger_entries", column: "reversed_entry_id"
  add_foreign_key "ledger_lines", "ledger_accounts", column: "account_id"
  add_foreign_key "ledger_lines", "ledger_entries", column: "entry_id"
end
