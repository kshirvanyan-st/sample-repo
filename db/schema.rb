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

ActiveRecord::Schema[8.1].define(version: 2026_10_18_200003) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"
  enable_extension "postgis"

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

  create_table "driver_locations", force: :cascade do |t|
    t.bigint "driver_profile_id", null: false
    t.geography "location", limit: {:srid=>4326, :type=>"st_point", :geographic=>true}, null: false
    t.float "heading"
    t.float "speed"
    t.datetime "recorded_at", null: false
    t.index ["driver_profile_id"], name: "index_driver_locations_on_driver_profile_id", unique: true
    t.index ["location"], name: "index_driver_locations_on_location", using: :gist
    t.index ["recorded_at"], name: "index_driver_locations_on_recorded_at"
  end

  create_table "driver_profiles", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.integer "status", default: 0, null: false
    t.string "license_number"
    t.date "license_expires_on"
    t.text "review_note"
    t.datetime "submitted_at"
    t.datetime "approved_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.datetime "online_at"
    t.index ["status", "submitted_at"], name: "index_driver_profiles_on_status_and_submitted_at"
    t.index ["user_id"], name: "index_driver_profiles_on_user_id", unique: true
    t.check_constraint "status >= 0 AND status <= 5", name: "driver_profiles_status_known"
  end

  create_table "expiry_notices", force: :cascade do |t|
    t.bigint "driver_profile_id", null: false
    t.string "document", null: false
    t.date "expires_on", null: false
    t.string "stage", null: false
    t.datetime "created_at", null: false
    t.index ["driver_profile_id", "document", "expires_on", "stage"], name: "index_expiry_notices_once", unique: true
  end

  create_table "fare_quotes", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.geography "pickup", limit: {:srid=>4326, :type=>"st_point", :geographic=>true}, null: false
    t.string "pickup_address"
    t.geography "dropoff", limit: {:srid=>4326, :type=>"st_point", :geographic=>true}, null: false
    t.string "dropoff_address"
    t.integer "distance_m", null: false
    t.integer "duration_s", null: false
    t.boolean "approximate", default: false, null: false
    t.jsonb "route", default: {}, null: false
    t.jsonb "prices", default: {}, null: false
    t.jsonb "tariffs", default: {}, null: false
    t.datetime "expires_at", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id"], name: "index_fare_quotes_on_user_id"
  end

  create_table "moderation_actions", force: :cascade do |t|
    t.bigint "moderator_id"
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

  create_table "service_zones", force: :cascade do |t|
    t.string "name", null: false
    t.boolean "active", default: true, null: false
    t.geography "area", limit: {:srid=>4326, :type=>"multi_polygon", :geographic=>true}, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["area"], name: "index_service_zones_on_area", using: :gist
  end

  create_table "sessions", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.string "ip_address"
    t.string "user_agent"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id"], name: "index_sessions_on_user_id"
  end

  create_table "tariffs", force: :cascade do |t|
    t.integer "vehicle_class", null: false
    t.integer "base_fare", null: false
    t.integer "per_km", null: false
    t.integer "per_minute", null: false
    t.integer "minimum_fare", null: false
    t.bigint "updated_by_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "cancellation_fee", default: 300, null: false
    t.integer "free_cancellation_minutes", default: 2, null: false
    t.index ["updated_by_id"], name: "index_tariffs_on_updated_by_id"
    t.index ["vehicle_class"], name: "index_tariffs_on_vehicle_class", unique: true
    t.check_constraint "base_fare >= 0 AND per_km >= 0 AND per_minute >= 0 AND minimum_fare >= 0", name: "tariffs_amounts_not_negative"
  end

  create_table "trip_offers", force: :cascade do |t|
    t.bigint "trip_id", null: false
    t.bigint "driver_profile_id", null: false
    t.integer "status", default: 0, null: false
    t.integer "eta_s"
    t.datetime "expires_at", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["driver_profile_id"], name: "index_trip_offers_on_driver_profile_id"
    t.index ["trip_id", "driver_profile_id"], name: "index_trip_offers_on_trip_id_and_driver_profile_id", unique: true
    t.check_constraint "status >= 0 AND status <= 3", name: "trip_offers_status_known"
  end

  create_table "trip_points", force: :cascade do |t|
    t.bigint "trip_id", null: false
    t.geography "location", limit: {:srid=>4326, :type=>"st_point", :geographic=>true}, null: false
    t.datetime "recorded_at", null: false
    t.index ["trip_id"], name: "index_trip_points_on_trip_id"
  end

  create_table "trips", force: :cascade do |t|
    t.bigint "rider_id", null: false
    t.bigint "driver_profile_id"
    t.bigint "fare_quote_id", null: false
    t.integer "vehicle_class", null: false
    t.integer "status", default: 0, null: false
    t.geography "pickup", limit: {:srid=>4326, :type=>"st_point", :geographic=>true}, null: false
    t.string "pickup_address"
    t.geography "dropoff", limit: {:srid=>4326, :type=>"st_point", :geographic=>true}, null: false
    t.string "dropoff_address"
    t.integer "fare", null: false
    t.integer "cancellation_fee", default: 0, null: false
    t.string "cancelled_by"
    t.string "cancel_reason"
    t.datetime "accepted_at"
    t.datetime "arrived_at"
    t.datetime "started_at"
    t.datetime "completed_at"
    t.datetime "cancelled_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["driver_profile_id", "created_at"], name: "index_trips_on_driver_profile_id_and_created_at"
    t.index ["driver_profile_id"], name: "index_trips_one_active_per_driver", unique: true, where: "(status = ANY (ARRAY[1, 2, 3]))"
    t.index ["fare_quote_id"], name: "index_trips_on_fare_quote_id"
    t.index ["rider_id"], name: "index_trips_on_rider_id"
    t.index ["rider_id"], name: "index_trips_one_open_per_rider", unique: true, where: "(status = ANY (ARRAY[0, 1, 2, 3]))"
    t.index ["status"], name: "index_trips_on_status"
    t.check_constraint "fare >= 0 AND cancellation_fee >= 0", name: "trips_money_not_negative"
    t.check_constraint "status >= 0 AND status <= 6", name: "trips_status_known"
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

  create_table "vehicles", force: :cascade do |t|
    t.bigint "driver_profile_id", null: false
    t.string "make"
    t.string "model"
    t.string "color"
    t.integer "year"
    t.string "plate_number"
    t.integer "vehicle_class", default: 0, null: false
    t.date "registration_expires_on"
    t.date "insurance_expires_on"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["driver_profile_id"], name: "index_vehicles_on_driver_profile_id", unique: true
    t.index ["plate_number"], name: "index_vehicles_on_plate_number", unique: true
  end

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
  add_foreign_key "driver_locations", "driver_profiles"
  add_foreign_key "driver_profiles", "users"
  add_foreign_key "expiry_notices", "driver_profiles"
  add_foreign_key "fare_quotes", "users"
  add_foreign_key "moderation_actions", "users"
  add_foreign_key "moderation_actions", "users", column: "moderator_id"
  add_foreign_key "saved_places", "users"
  add_foreign_key "sessions", "users"
  add_foreign_key "tariffs", "users", column: "updated_by_id"
  add_foreign_key "trip_offers", "driver_profiles"
  add_foreign_key "trip_offers", "trips"
  add_foreign_key "trip_points", "trips"
  add_foreign_key "trips", "driver_profiles"
  add_foreign_key "trips", "fare_quotes"
  add_foreign_key "trips", "users", column: "rider_id"
  add_foreign_key "vehicles", "driver_profiles"
end
