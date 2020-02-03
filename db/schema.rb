# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `rails
# db:schema:load`. When creating a new database, `rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 2020_02_03_201932) do

  create_table "active_storage_attachments", force: :cascade do |t|
    t.string "name", null: false
    t.string "record_type", null: false
    t.integer "record_id", null: false
    t.integer "blob_id", null: false
    t.datetime "created_at", null: false
    t.index ["blob_id"], name: "index_active_storage_attachments_on_blob_id"
    t.index ["record_type", "record_id", "name", "blob_id"], name: "index_active_storage_attachments_uniqueness", unique: true
  end

  create_table "active_storage_blobs", force: :cascade do |t|
    t.string "key", null: false
    t.string "filename", null: false
    t.string "content_type"
    t.text "metadata"
    t.bigint "byte_size", null: false
    t.string "checksum", null: false
    t.datetime "created_at", null: false
    t.index ["key"], name: "index_active_storage_blobs_on_key", unique: true
  end

  create_table "ledger_bases", force: :cascade do |t|
    t.string "type", default: "LedgerBase"
    t.boolean "bool1", default: false
    t.datetime "date1", default: "0001-01-01 00:00:00"
    t.integer "number1", default: 0
    t.string "string1", default: ""
    t.text "text1", default: ""
    t.integer "creator_id", null: false
    t.integer "original_id"
    t.integer "amended_id"
    t.integer "deleted_id"
    t.integer "ledger1_id"
    t.float "current_down_points", default: 0.0
    t.float "current_meh_points", default: 0.0
    t.float "current_up_points", default: 0.0
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["amended_id"], name: "index_ledger_bases_on_amended_id"
    t.index ["creator_id"], name: "index_ledger_bases_on_creator_id"
    t.index ["deleted_id"], name: "index_ledger_bases_on_deleted_id"
    t.index ["ledger1_id"], name: "index_ledger_bases_on_ledger1_id"
    t.index ["original_id"], name: "index_ledger_bases_on_original_id"
  end

  create_table "microposts", force: :cascade do |t|
    t.text "content"
    t.integer "user_id", null: false
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.integer "images_number", default: 0
    t.index ["user_id", "created_at"], name: "index_microposts_on_user_id_and_created_at"
    t.index ["user_id"], name: "index_microposts_on_user_id"
  end

  create_table "relationships", force: :cascade do |t|
    t.integer "follower_id"
    t.integer "followed_id"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["followed_id"], name: "index_relationships_on_followed_id"
    t.index ["follower_id", "followed_id"], name: "index_relationships_on_follower_id_and_followed_id", unique: true
    t.index ["follower_id"], name: "index_relationships_on_follower_id"
  end

  create_table "users", force: :cascade do |t|
    t.string "name"
    t.string "email"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.string "password_digest"
    t.string "remember_digest"
    t.boolean "admin", default: false
    t.string "activation_digest"
    t.boolean "activated", default: false
    t.datetime "activated_at"
    t.string "reset_digest"
    t.datetime "reset_sent_at"
    t.index ["email"], name: "index_users_on_email", unique: true
  end

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "ledger_bases", "ledger_bases", column: "amended_id"
  add_foreign_key "ledger_bases", "ledger_bases", column: "creator_id"
  add_foreign_key "ledger_bases", "ledger_bases", column: "deleted_id"
  add_foreign_key "ledger_bases", "ledger_bases", column: "ledger1_id"
  add_foreign_key "ledger_bases", "ledger_bases", column: "original_id"
  add_foreign_key "microposts", "users"
end
