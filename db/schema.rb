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

ActiveRecord::Schema[7.0].define(version: 2024_02_07_074103) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "active_admin_comments", force: :cascade do |t|
    t.string "namespace"
    t.text "body"
    t.string "resource_type"
    t.bigint "resource_id"
    t.string "author_type"
    t.bigint "author_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["author_type", "author_id"], name: "index_active_admin_comments_on_author"
    t.index ["namespace"], name: "index_active_admin_comments_on_namespace"
    t.index ["resource_type", "resource_id"], name: "index_active_admin_comments_on_resource"
  end

  create_table "channel_stats", force: :cascade do |t|
    t.bigint "channel_id"
    t.integer "subscribers"
    t.string "title"
    t.datetime "created_at", precision: nil, null: false
    t.text "description"
    t.boolean "prometheus", default: false, null: false
    t.integer "average_views"
    t.index ["channel_id"], name: "index_channel_stats_on_channel_id"
  end

  create_table "channel_tests", force: :cascade do |t|
    t.integer "subscribers"
    t.text "title"
    t.text "description"
    t.boolean "is_verify"
    t.text "avatar_url"
    t.datetime "update_info_at"
    t.boolean "by_web_parse"
    t.boolean "by_telethon_parse"
    t.datetime "updated_parse_mode_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "channel_themes", force: :cascade do |t|
    t.string "title"
  end

  create_table "channels", force: :cascade do |t|
    t.string "name"
    t.string "joinchat"
    t.string "tg_id"
    t.string "title"
    t.text "description"
    t.boolean "inner", default: false
    t.datetime "get_last_posts_at", default: "2000-01-01 00:00:00", null: false
    t.datetime "update_info_at", default: "2000-01-01 00:00:00", null: false
    t.integer "subscribers", default: 0
    t.boolean "is_private"
    t.datetime "apr_calculated_at", default: "2000-01-01 00:00:00", null: false
    t.jsonb "stat", default: [], array: true
    t.boolean "broadcast"
    t.string "new_tg_id"
    t.string "lang"
    t.datetime "last_post_date"
    t.boolean "is_verify"
    t.integer "last_post_id"
    t.boolean "by_web_parse"
    t.boolean "by_telethon_parse"
    t.datetime "updated_parse_mode_at"
    t.text "avatar_url"
    t.boolean "from_external_link", default: false
    t.float "last_eternal_err", default: 0.0
    t.float "last_eternal_apr", default: 0.0
    t.integer "average_views", default: 0
    t.datetime "avatar_updated_at"
    t.boolean "is_empty", default: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["joinchat"], name: "index_channels_on_joinchat"
    t.index ["name"], name: "index_channels_on_name"
  end

  create_table "channels_stats", force: :cascade do |t|
    t.bigint "channel_id", null: false
    t.integer "subscribers", null: false
    t.string "title"
    t.text "description"
    t.integer "average_views"
    t.datetime "created_at", default: -> { "CURRENT_TIMESTAMP" }, null: false
  end

  create_table "freelancer_theme_ties", force: :cascade do |t|
    t.integer "freelancer_id"
    t.integer "channel_theme_id"
    t.boolean "active", default: false
    t.boolean "complete", default: false
    t.integer "channel_id"
    t.index ["freelancer_id"], name: "index_freelancer_theme_ties_on_freelancer_id"
  end

  create_table "freelancers", force: :cascade do |t|
    t.string "login"
    t.string "password"
    t.integer "complete_count", default: 0
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "parsing_logs", force: :cascade do |t|
    t.integer "count_rows", default: 0, null: false
    t.datetime "start_date"
    t.datetime "end_date"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "posts", force: :cascade do |t|
    t.bigint "channel_id"
    t.string "link", null: false
    t.string "kind"
    t.integer "views"
    t.boolean "has_photo"
    t.boolean "has_video"
    t.decimal "top_hours", default: "0.0", null: false
    t.decimal "feed_hours", default: "0.0", null: false
    t.datetime "published_at", precision: nil
    t.datetime "deleted_at", precision: nil
    t.datetime "next_post_at", precision: nil
    t.text "html"
    t.jsonb "links"
    t.jsonb "statistic", default: [], null: false
    t.boolean "skip_screen", default: false, null: false
    t.integer "prometheus_id"
    t.integer "tg_id", null: false
    t.boolean "campaign", default: false, null: false
    t.string "screenshot"
    t.integer "order_channel_id"
    t.boolean "has_external_links"
    t.datetime "scheduled_parsing_at"
    t.datetime "last_parsed_at"
    t.boolean "is_marking"
    t.boolean "is_repost", default: false
    t.boolean "is_checked_clicks", default: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["campaign"], name: "index_posts_on_campaign"
    t.index ["channel_id"], name: "index_posts_on_channel_id"
    t.index ["link"], name: "index_posts_on_link", unique: true
    t.index ["tg_id"], name: "index_posts_on_tg_id"
  end

  create_table "users", force: :cascade do |t|
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
  end

end
