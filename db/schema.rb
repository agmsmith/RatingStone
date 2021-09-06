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

ActiveRecord::Schema.define(version: 2021_01_08_211619) do

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
    t.integer "byte_size", null: false
    t.string "checksum", null: false
    t.datetime "created_at", null: false
    t.string "service_name", null: false
    t.index ["key"], name: "index_active_storage_blobs_on_key", unique: true
  end

  create_table "active_storage_variant_records", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.string "variation_digest", null: false
    t.index ["blob_id", "variation_digest"], name: "index_active_storage_variant_records_uniqueness", unique: true
  end

  create_table "aux_ledgers", force: :cascade do |t|
    t.bigint "parent_id", null: false
    t.bigint "child_id", null: false
    t.index ["child_id"], name: "index_aux_ledgers_on_child_id"
    t.index ["parent_id"], name: "index_aux_ledgers_on_parent_id"
  end

  create_table "aux_links", force: :cascade do |t|
    t.bigint "parent_id", null: false
    t.bigint "child_id", null: false
    t.index ["child_id"], name: "index_aux_links_on_child_id"
    t.index ["parent_id"], name: "index_aux_links_on_parent_id"
  end

  create_table "clips", force: :cascade do |t|
    t.bigint "ledger_user_id", null: false
    t.bigint "ledger_object_id"
    t.bigint "link_object_id"
    t.string "description", default: ""
    t.index ["ledger_object_id"], name: "index_clips_on_ledger_object_id"
    t.index ["ledger_user_id"], name: "index_clips_on_ledger_user_id"
    t.index ["link_object_id"], name: "index_clips_on_link_object_id"
  end

  create_table "group_settings", force: :cascade do |t|
    t.bigint "ledger_full_group_id", null: false
    t.boolean "auto_approve_non_member_posts", default: false
    t.boolean "auto_approve_member_posts", default: true
    t.boolean "auto_approve_members", default: false
    t.float "min_points_non_member_post", default: -1.0
    t.float "max_points_non_member_post", default: 2.0
    t.float "min_points_member_post", default: -10.0
    t.float "max_points_member_post", default: 10.0
    t.float "min_points_membership", default: 1.0
    t.float "max_points_membership", default: 100.0
    t.string "wildcard_role_banned", default: ""
    t.string "wildcard_role_reader", default: ""
    t.string "wildcard_role_member", default: ""
    t.string "wildcard_role_message_moderator", default: ""
    t.string "wildcard_role_meta_moderator", default: ""
    t.string "wildcard_role_member_moderator", default: ""
    t.index ["ledger_full_group_id"], name: "index_group_settings_on_ledger_full_group_id"
  end

  create_table "ledger_bases", force: :cascade do |t|
    t.string "type", default: "LedgerBase"
    t.bigint "original_id"
    t.bigint "amended_id"
    t.boolean "deleted", default: false
    t.boolean "expired_now", default: false
    t.boolean "expired_soon", default: false
    t.boolean "has_owners", default: false
    t.boolean "is_latest_version", default: true
    t.bigint "creator_id", null: false
    t.boolean "bool1", default: false
    t.bigint "number1", default: 0
    t.string "string1", default: ""
    t.string "string2", default: ""
    t.text "text1", default: ""
    t.datetime "date1"
    t.float "current_down_points", default: 0.0
    t.float "current_meh_points", default: 0.0
    t.float "current_up_points", default: 0.0
    t.integer "current_ceremony", default: -1
    t.integer "original_ceremony", default: -1
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["amended_id"], name: "index_ledger_bases_on_amended_id"
    t.index ["creator_id"], name: "index_ledger_bases_on_creator_id"
    t.index ["number1"], name: "index_ledger_bases_on_number1"
    t.index ["original_id"], name: "index_ledger_bases_on_original_id"
    t.index ["string1"], name: "index_ledger_bases_on_string1"
    t.index ["string2"], name: "index_ledger_bases_on_string2"
  end

  create_table "link_bases", force: :cascade do |t|
    t.string "type", default: "LinkBase"
    t.bigint "parent_id", null: false
    t.bigint "child_id", null: false
    t.bigint "creator_id", null: false
    t.bigint "number1", default: 0
    t.string "string1", default: ""
    t.boolean "deleted", default: false
    t.boolean "approved_parent", default: false
    t.boolean "approved_child", default: false
    t.float "rating_points_spent", default: 0.0
    t.float "rating_points_boost_parent", default: 0.0
    t.float "rating_points_boost_child", default: 0.0
    t.string "rating_direction_parent", default: "M"
    t.string "rating_direction_child", default: "M"
    t.integer "original_ceremony", default: -1
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["child_id"], name: "index_link_bases_on_child_id"
    t.index ["creator_id"], name: "index_link_bases_on_creator_id"
    t.index ["number1"], name: "index_link_bases_on_number1"
    t.index ["parent_id"], name: "index_link_bases_on_parent_id"
    t.index ["string1"], name: "index_link_bases_on_string1"
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
    t.bigint "ledger_user_id"
    t.float "entitlement_remaining", default: 0.0
    t.index ["email"], name: "index_users_on_email", unique: true
  end

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
  add_foreign_key "aux_ledgers", "ledger_bases", column: "child_id"
  add_foreign_key "aux_ledgers", "ledger_bases", column: "parent_id"
  add_foreign_key "aux_links", "ledger_bases", column: "parent_id"
  add_foreign_key "aux_links", "link_bases", column: "child_id"
  add_foreign_key "clips", "ledger_bases", column: "ledger_object_id"
  add_foreign_key "clips", "ledger_bases", column: "ledger_user_id"
  add_foreign_key "clips", "link_bases", column: "link_object_id"
  add_foreign_key "group_settings", "ledger_bases", column: "ledger_full_group_id"
  add_foreign_key "ledger_bases", "ledger_bases", column: "amended_id"
  add_foreign_key "ledger_bases", "ledger_bases", column: "creator_id"
  add_foreign_key "ledger_bases", "ledger_bases", column: "original_id"
  add_foreign_key "link_bases", "ledger_bases", column: "child_id"
  add_foreign_key "link_bases", "ledger_bases", column: "creator_id"
  add_foreign_key "link_bases", "ledger_bases", column: "parent_id"
end
