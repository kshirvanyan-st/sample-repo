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

ActiveRecord::Schema[8.1].define(version: 2026_10_18_170005) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"
  enable_extension "postgis"

  create_table "moderation_actions", force: :cascade do |t|
    t.bigint "moderator_id", null: false
    t.bigint "user_id", null: false
    t.string "action", null: false
    t.jsonb "details", default: {}, null: false
    t.datetime "created_at", null: false
    t.index ["moderator_id"], name: "index_moderation_actions_on_moderator_id"
    t.index ["user_id"], name: "index_moderation_actions_on_user_id"
  end

  create_table "phone_verifications", force: :cascade do |t|
    t.string "phone", null: false
    t.string "code_digest", null: false
    t.datetime "expires_at", null: false
    t.integer "attempts", default: 0, null: false
    t.datetime "consumed_at"
    t.string "ip_address"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["phone", "created_at"], name: "index_phone_verifications_on_phone_and_created_at"
  end

  create_table "saved_places", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.integer "kind", default: 2, null: false
    t.string "label"
    t.string "address", null: false
    t.geography "location", limit: {:srid=>4326, :type=>"st_point", :geographic=>true}
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["location"], name: "index_saved_places_on_location", using: :gist
    t.index ["user_id", "kind"], name: "index_saved_places_one_home_one_work", unique: true, where: "(kind = ANY (ARRAY[0, 1]))"
    t.index ["user_id"], name: "index_saved_places_on_user_id"
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
    t.string "phone", null: false
    t.string "name"
    t.integer "role", default: 0, null: false
    t.string "locale"
    t.datetime "banned_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["phone"], name: "index_users_on_phone", unique: true
    t.check_constraint "role = ANY (ARRAY[0, 1, 2, 3])", name: "users_role_known"
  end

  add_foreign_key "moderation_actions", "users"
  add_foreign_key "moderation_actions", "users", column: "moderator_id"
  add_foreign_key "saved_places", "users"
  add_foreign_key "sessions", "users"
end
