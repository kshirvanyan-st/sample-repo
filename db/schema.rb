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

ActiveRecord::Schema[8.1].define(version: 2026_10_18_110005) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "cube"
  enable_extension "earthdistance"
  enable_extension "pg_catalog.plpgsql"

  create_table "active_storage_attachments", force: :cascade do |t|
    t.string "name", null: false
    t.string "record_type", null: false
    t.bigint "record_id", null: false
    t.bigint "blob_id", null: false
    t.datetime "created_at", null: false
    t.index ["blob_id"], name: "index_active_storage_attachments_on_blob_id"
    t.index ["record_type", "record_id", "name", "blob_id"], name: "index_active_storage_attachments_uniqueness", unique: true
  end

  create_table "active_storage_blobs", force: :cascade do |t|
    t.string "key", null: false
    t.string "filename", null: false
    t.string "content_type"
    t.text "metadata"
    t.string "service_name", null: false
    t.bigint "byte_size", null: false
    t.string "checksum"
    t.datetime "created_at", null: false
    t.index ["key"], name: "index_active_storage_blobs_on_key", unique: true
  end

  create_table "active_storage_variant_records", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.string "variation_digest", null: false
    t.index ["blob_id", "variation_digest"], name: "index_active_storage_variant_records_uniqueness", unique: true
  end

  create_table "blocks", force: :cascade do |t|
    t.bigint "blocker_id", null: false
    t.bigint "blocked_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["blocked_id"], name: "index_blocks_on_blocked_id"
    t.index ["blocker_id", "blocked_id"], name: "index_blocks_on_blocker_id_and_blocked_id", unique: true
    t.check_constraint "blocker_id <> blocked_id", name: "blocks_not_self"
  end

  create_table "follows", force: :cascade do |t|
    t.bigint "follower_id", null: false
    t.bigint "followee_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["followee_id"], name: "index_follows_on_followee_id"
    t.index ["follower_id", "followee_id"], name: "index_follows_on_follower_id_and_followee_id", unique: true
    t.check_constraint "follower_id <> followee_id", name: "follows_not_self"
  end

  create_table "likes", force: :cascade do |t|
    t.bigint "liker_id", null: false
    t.bigint "likee_id", null: false
    t.integer "kind", default: 0, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["likee_id", "kind"], name: "index_likes_on_likee_id_and_kind"
    t.index ["liker_id", "likee_id"], name: "index_likes_on_liker_id_and_likee_id", unique: true
    t.check_constraint "liker_id <> likee_id", name: "likes_not_self"
  end

  create_table "matches", force: :cascade do |t|
    t.bigint "user_a_id", null: false
    t.bigint "user_b_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_a_id", "user_b_id"], name: "index_matches_on_user_a_id_and_user_b_id", unique: true
    t.index ["user_b_id"], name: "index_matches_on_user_b_id"
    t.check_constraint "user_a_id < user_b_id", name: "matches_ordered_pair"
  end

  create_table "photos", force: :cascade do |t|
    t.bigint "profile_id", null: false
    t.integer "position", default: 0, null: false
    t.integer "status", default: 0, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["profile_id", "position"], name: "index_photos_on_profile_id_and_position"
  end

  create_table "profiles", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.string "display_name", null: false
    t.date "birthdate", null: false
    t.integer "gender", default: 0, null: false
    t.integer "looking_for", default: 0, null: false
    t.string "city"
    t.text "bio"
    t.decimal "latitude", precision: 10, scale: 6
    t.decimal "longitude", precision: 10, scale: 6
    t.datetime "onboarded_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "age_min", default: 18, null: false
    t.integer "age_max", default: 99, null: false
    t.integer "max_distance_km", default: 50
    t.index "ll_to_earth((latitude)::double precision, (longitude)::double precision)", name: "index_profiles_on_location", where: "((latitude IS NOT NULL) AND (longitude IS NOT NULL))", using: :gist
    t.index ["user_id"], name: "index_profiles_on_user_id", unique: true
  end

  create_table "reports", force: :cascade do |t|
    t.bigint "reporter_id", null: false
    t.bigint "reported_id", null: false
    t.integer "reason", default: 0, null: false
    t.text "details"
    t.integer "status", default: 0, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["reported_id"], name: "index_reports_on_reported_id"
    t.index ["reporter_id"], name: "index_reports_on_reporter_id"
    t.index ["status"], name: "index_reports_on_status"
  end

  create_table "sessions", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.string "ip_address"
    t.string "user_agent"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id"], name: "index_sessions_on_user_id"
  end

  create_table "users", force: :cascade do |t|
    t.string "email_address", null: false
    t.string "password_digest", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["email_address"], name: "index_users_on_email_address", unique: true
  end

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
  add_foreign_key "blocks", "users", column: "blocked_id"
  add_foreign_key "blocks", "users", column: "blocker_id"
  add_foreign_key "follows", "users", column: "followee_id"
  add_foreign_key "follows", "users", column: "follower_id"
  add_foreign_key "likes", "users", column: "likee_id"
  add_foreign_key "likes", "users", column: "liker_id"
  add_foreign_key "matches", "users", column: "user_a_id"
  add_foreign_key "matches", "users", column: "user_b_id"
  add_foreign_key "photos", "profiles"
  add_foreign_key "profiles", "users"
  add_foreign_key "reports", "users", column: "reported_id"
  add_foreign_key "reports", "users", column: "reporter_id"
  add_foreign_key "sessions", "users"
end
