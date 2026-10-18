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

ActiveRecord::Schema[8.1].define(version: 2026_10_18_150007) do
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

  create_table "ahoy_events", force: :cascade do |t|
    t.bigint "visit_id"
    t.bigint "user_id"
    t.string "name"
    t.jsonb "properties"
    t.datetime "time"
    t.index ["name", "time"], name: "index_ahoy_events_on_name_and_time"
    t.index ["properties"], name: "index_ahoy_events_on_properties", opclass: :jsonb_path_ops, using: :gin
    t.index ["user_id"], name: "index_ahoy_events_on_user_id"
    t.index ["visit_id"], name: "index_ahoy_events_on_visit_id"
  end

  create_table "ahoy_visits", force: :cascade do |t|
    t.string "visit_token"
    t.string "visitor_token"
    t.bigint "user_id"
    t.string "ip"
    t.text "user_agent"
    t.text "referrer"
    t.string "referring_domain"
    t.text "landing_page"
    t.string "browser"
    t.string "os"
    t.string "device_type"
    t.string "country"
    t.string "region"
    t.string "city"
    t.float "latitude"
    t.float "longitude"
    t.string "utm_source"
    t.string "utm_medium"
    t.string "utm_term"
    t.string "utm_content"
    t.string "utm_campaign"
    t.string "app_version"
    t.string "os_version"
    t.string "platform"
    t.datetime "started_at"
    t.index ["user_id"], name: "index_ahoy_visits_on_user_id"
    t.index ["visit_token"], name: "index_ahoy_visits_on_visit_token", unique: true
    t.index ["visitor_token", "started_at"], name: "index_ahoy_visits_on_visitor_token_and_started_at"
  end

  create_table "blazer_audits", force: :cascade do |t|
    t.bigint "user_id"
    t.bigint "query_id"
    t.text "statement"
    t.string "data_source"
    t.datetime "created_at"
    t.index ["query_id"], name: "index_blazer_audits_on_query_id"
    t.index ["user_id"], name: "index_blazer_audits_on_user_id"
  end

  create_table "blazer_checks", force: :cascade do |t|
    t.bigint "creator_id"
    t.bigint "query_id"
    t.string "state"
    t.string "schedule"
    t.text "emails"
    t.text "slack_channels"
    t.string "check_type"
    t.text "message"
    t.datetime "last_run_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["creator_id"], name: "index_blazer_checks_on_creator_id"
    t.index ["query_id"], name: "index_blazer_checks_on_query_id"
  end

  create_table "blazer_dashboard_queries", force: :cascade do |t|
    t.bigint "dashboard_id"
    t.bigint "query_id"
    t.integer "position"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["dashboard_id"], name: "index_blazer_dashboard_queries_on_dashboard_id"
    t.index ["query_id"], name: "index_blazer_dashboard_queries_on_query_id"
  end

  create_table "blazer_dashboards", force: :cascade do |t|
    t.bigint "creator_id"
    t.string "name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["creator_id"], name: "index_blazer_dashboards_on_creator_id"
  end

  create_table "blazer_queries", force: :cascade do |t|
    t.bigint "creator_id"
    t.string "name"
    t.text "description"
    t.text "statement"
    t.string "data_source"
    t.string "status"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["creator_id"], name: "index_blazer_queries_on_creator_id"
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

  create_table "coin_packs", force: :cascade do |t|
    t.string "name", null: false
    t.integer "coins", null: false
    t.integer "bonus_coins", default: 0, null: false
    t.integer "price_cents", null: false
    t.string "currency", default: "usd", null: false
    t.boolean "active", default: true, null: false
    t.integer "position", default: 0, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "conversations", force: :cascade do |t|
    t.bigint "match_id", null: false
    t.datetime "last_message_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["match_id"], name: "index_conversations_on_match_id", unique: true
  end

  create_table "daily_metrics", force: :cascade do |t|
    t.date "date", null: false
    t.integer "signups", default: 0, null: false
    t.integer "active_users", default: 0, null: false
    t.integer "payers", default: 0, null: false
    t.integer "purchases", default: 0, null: false
    t.integer "revenue_cents", default: 0, null: false
    t.integer "refunds_cents", default: 0, null: false
    t.integer "coins_purchased", default: 0, null: false
    t.integer "coins_spent", default: 0, null: false
    t.integer "gift_coins", default: 0, null: false
    t.integer "matches", default: 0, null: false
    t.integer "messages", default: 0, null: false
    t.integer "streams", default: 0, null: false
    t.integer "viewer_seconds", default: 0, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["date"], name: "index_daily_metrics_on_date", unique: true
  end

  create_table "field_test_memberships", force: :cascade do |t|
    t.string "participant_type"
    t.string "participant_id"
    t.string "experiment"
    t.string "variant"
    t.datetime "created_at"
    t.boolean "converted", default: false
    t.index ["experiment", "created_at"], name: "index_field_test_memberships_on_experiment_and_created_at"
    t.index ["participant_type", "participant_id", "experiment"], name: "index_field_test_memberships_on_participant", unique: true
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

  create_table "gift_transactions", force: :cascade do |t|
    t.bigint "gift_id", null: false
    t.bigint "stream_id", null: false
    t.bigint "sender_id", null: false
    t.bigint "recipient_id", null: false
    t.integer "coins", null: false
    t.datetime "created_at", null: false
    t.index ["gift_id"], name: "index_gift_transactions_on_gift_id"
    t.index ["recipient_id"], name: "index_gift_transactions_on_recipient_id"
    t.index ["sender_id"], name: "index_gift_transactions_on_sender_id"
    t.index ["stream_id", "sender_id"], name: "index_gift_transactions_on_stream_id_and_sender_id"
    t.index ["stream_id"], name: "index_gift_transactions_on_stream_id"
    t.check_constraint "coins > 0", name: "gift_transactions_coins_positive"
    t.check_constraint "sender_id <> recipient_id", name: "gift_transactions_not_self"
  end

  create_table "gifts", force: :cascade do |t|
    t.string "name", null: false
    t.string "emoji", null: false
    t.integer "coins", null: false
    t.boolean "active", default: true, null: false
    t.integer "position", default: 0, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "ledger_entries", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.integer "account", null: false
    t.integer "kind", null: false
    t.integer "amount", null: false
    t.integer "balance_after", null: false
    t.string "reference_type"
    t.bigint "reference_id"
    t.datetime "created_at", null: false
    t.index ["reference_type", "reference_id"], name: "index_ledger_entries_on_reference"
    t.index ["user_id", "account", "created_at"], name: "index_ledger_entries_on_user_id_and_account_and_created_at"
    t.check_constraint "amount <> 0", name: "ledger_entries_amount_not_zero"
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

  create_table "messages", force: :cascade do |t|
    t.bigint "conversation_id", null: false
    t.bigint "sender_id", null: false
    t.text "body", null: false
    t.datetime "read_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["conversation_id", "created_at"], name: "index_messages_on_conversation_id_and_created_at"
    t.index ["conversation_id", "sender_id"], name: "index_messages_unread", where: "(read_at IS NULL)"
    t.index ["sender_id"], name: "index_messages_on_sender_id"
  end

  create_table "moderation_actions", force: :cascade do |t|
    t.bigint "moderator_id", null: false
    t.string "action", null: false
    t.string "target_type", null: false
    t.bigint "target_id", null: false
    t.string "note"
    t.datetime "created_at", null: false
    t.index ["created_at"], name: "index_moderation_actions_on_created_at"
    t.index ["moderator_id"], name: "index_moderation_actions_on_moderator_id"
    t.index ["target_type", "target_id"], name: "index_moderation_actions_on_target"
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

  create_table "purchases", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.bigint "coin_pack_id", null: false
    t.integer "coins", null: false
    t.integer "amount_cents", null: false
    t.string "currency", null: false
    t.integer "status", default: 0, null: false
    t.string "stripe_checkout_session_id"
    t.string "stripe_payment_intent_id"
    t.datetime "paid_at"
    t.datetime "refunded_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["coin_pack_id"], name: "index_purchases_on_coin_pack_id"
    t.index ["stripe_checkout_session_id"], name: "index_purchases_on_stripe_checkout_session_id", unique: true
    t.index ["stripe_payment_intent_id"], name: "index_purchases_on_stripe_payment_intent_id"
    t.index ["user_id"], name: "index_purchases_on_user_id"
  end

  create_table "reports", force: :cascade do |t|
    t.bigint "reporter_id", null: false
    t.bigint "reported_id", null: false
    t.integer "reason", default: 0, null: false
    t.text "details"
    t.integer "status", default: 0, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "resolved_by_id"
    t.datetime "resolved_at"
    t.integer "resolution"
    t.index ["reported_id"], name: "index_reports_on_reported_id"
    t.index ["reporter_id"], name: "index_reports_on_reporter_id"
    t.index ["resolved_by_id"], name: "index_reports_on_resolved_by_id"
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

  create_table "stream_comments", force: :cascade do |t|
    t.bigint "stream_id", null: false
    t.bigint "user_id", null: false
    t.string "body", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["stream_id", "created_at"], name: "index_stream_comments_on_stream_id_and_created_at"
    t.index ["user_id"], name: "index_stream_comments_on_user_id"
  end

  create_table "stream_viewers", force: :cascade do |t|
    t.bigint "stream_id", null: false
    t.bigint "user_id", null: false
    t.string "connection_token", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["connection_token"], name: "index_stream_viewers_on_connection_token", unique: true
    t.index ["stream_id"], name: "index_stream_viewers_on_stream_id"
    t.index ["user_id"], name: "index_stream_viewers_on_user_id"
  end

  create_table "streams", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.string "title", null: false
    t.integer "category", default: 0, null: false
    t.integer "status", default: 0, null: false
    t.datetime "started_at"
    t.datetime "ended_at"
    t.integer "viewers_count", default: 0, null: false
    t.integer "peak_viewers", default: 0, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "ingest_protocol"
    t.integer "viewer_seconds", default: 0, null: false
    t.index ["status"], name: "index_streams_live", where: "(status = 1)"
    t.index ["user_id", "created_at"], name: "index_streams_on_user_id_and_created_at"
    t.index ["user_id"], name: "index_streams_one_open_per_user", unique: true, where: "(status = ANY (ARRAY[0, 1]))"
  end

  create_table "stripe_events", force: :cascade do |t|
    t.string "stripe_event_id", null: false
    t.string "event_type", null: false
    t.datetime "created_at", null: false
    t.index ["stripe_event_id"], name: "index_stripe_events_on_stripe_event_id", unique: true
  end

  create_table "users", force: :cascade do |t|
    t.string "email_address", null: false
    t.string "password_digest", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "stream_path"
    t.string "stream_key"
    t.integer "coin_balance", default: 0, null: false
    t.integer "earnings_balance", default: 0, null: false
    t.integer "role", default: 0, null: false
    t.datetime "banned_at"
    t.string "ban_reason"
    t.datetime "streaming_suspended_at"
    t.index ["banned_at"], name: "index_users_on_banned_at", where: "(banned_at IS NOT NULL)"
    t.index ["email_address"], name: "index_users_on_email_address", unique: true
    t.index ["stream_path"], name: "index_users_on_stream_path", unique: true
    t.check_constraint "coin_balance >= 0", name: "users_coin_balance_not_negative"
    t.check_constraint "earnings_balance >= 0", name: "users_earnings_balance_not_negative"
  end

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
  add_foreign_key "blocks", "users", column: "blocked_id"
  add_foreign_key "blocks", "users", column: "blocker_id"
  add_foreign_key "conversations", "matches", on_delete: :cascade
  add_foreign_key "follows", "users", column: "followee_id"
  add_foreign_key "follows", "users", column: "follower_id"
  add_foreign_key "gift_transactions", "gifts"
  add_foreign_key "gift_transactions", "streams"
  add_foreign_key "gift_transactions", "users", column: "recipient_id"
  add_foreign_key "gift_transactions", "users", column: "sender_id"
  add_foreign_key "ledger_entries", "users"
  add_foreign_key "likes", "users", column: "likee_id"
  add_foreign_key "likes", "users", column: "liker_id"
  add_foreign_key "matches", "users", column: "user_a_id"
  add_foreign_key "matches", "users", column: "user_b_id"
  add_foreign_key "messages", "conversations", on_delete: :cascade
  add_foreign_key "messages", "users", column: "sender_id"
  add_foreign_key "moderation_actions", "users", column: "moderator_id"
  add_foreign_key "photos", "profiles"
  add_foreign_key "profiles", "users"
  add_foreign_key "purchases", "coin_packs"
  add_foreign_key "purchases", "users"
  add_foreign_key "reports", "users", column: "reported_id"
  add_foreign_key "reports", "users", column: "reporter_id"
  add_foreign_key "reports", "users", column: "resolved_by_id"
  add_foreign_key "sessions", "users"
  add_foreign_key "stream_comments", "streams", on_delete: :cascade
  add_foreign_key "stream_comments", "users", on_delete: :cascade
  add_foreign_key "stream_viewers", "streams", on_delete: :cascade
  add_foreign_key "stream_viewers", "users", on_delete: :cascade
  add_foreign_key "streams", "users"
end
