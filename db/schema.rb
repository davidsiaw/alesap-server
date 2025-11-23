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

ActiveRecord::Schema[8.1].define(version: 3000_01_01_000004) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "citext"
  enable_extension "pg_catalog.plpgsql"
  enable_extension "pgcrypto"

  create_table "admins", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.datetime "confirmation_sent_at", precision: nil
    t.string "confirmation_token"
    t.datetime "confirmed_at", precision: nil
    t.datetime "current_sign_in_at", precision: nil
    t.inet "current_sign_in_ip"
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.integer "failed_attempts", default: 0, null: false
    t.datetime "last_sign_in_at", precision: nil
    t.inet "last_sign_in_ip"
    t.datetime "locked_at", precision: nil
    t.datetime "remember_created_at", precision: nil
    t.datetime "reset_password_sent_at", precision: nil
    t.string "reset_password_token"
    t.integer "sign_in_count", default: 0, null: false
    t.string "unconfirmed_email"
    t.string "unlock_token"
    t.datetime "updated_at", precision: nil
    t.index ["confirmation_token"], name: "index_admins_on_confirmation_token", unique: true
    t.index ["email"], name: "index_admins_on_email", unique: true
    t.index ["reset_password_token"], name: "index_admins_on_reset_password_token", unique: true
    t.index ["unlock_token"], name: "index_admins_on_unlock_token", unique: true
  end

  create_table "commands", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.integer "amount", null: false
    t.string "subject", default: "", null: false
    t.datetime "updated_at", precision: nil
    t.string "verb", default: "", null: false
    t.index ["amount"], name: "index_commands_on_amount"
    t.index ["subject"], name: "index_commands_on_subject"
    t.index ["updated_at"], name: "index_commands_on_updated_at"
    t.index ["verb"], name: "index_commands_on_verb"
  end

  create_table "istrings", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "str", default: "", null: false
    t.datetime "updated_at", precision: nil
    t.index ["str"], name: "index_istrings_on_str"
    t.index ["updated_at"], name: "index_istrings_on_updated_at"
  end

  create_table "pasela_artists", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "artist_name_id", null: false
    t.string "master_singer_id", default: "", null: false
    t.datetime "updated_at", precision: nil
    t.index ["artist_name_id"], name: "index_pasela_artists_on_artist_name_id"
    t.index ["master_singer_id"], name: "index_pasela_artists_on_master_singer_id"
    t.index ["updated_at"], name: "index_pasela_artists_on_updated_at"
  end

  create_table "pasela_esong_pasela_artists", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "artist_id", null: false
    t.uuid "song_id", null: false
    t.datetime "updated_at", precision: nil
    t.index ["artist_id"], name: "index_pasela_esong_pasela_artists_on_artist_id"
    t.index ["song_id"], name: "index_pasela_esong_pasela_artists_on_song_id"
    t.index ["updated_at"], name: "index_pasela_esong_pasela_artists_on_updated_at"
  end

  create_table "pasela_esongs", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "esong_key", default: "", null: false
    t.uuid "name_id", null: false
    t.uuid "ruby_id", null: false
    t.datetime "updated_at", precision: nil
    t.index ["esong_key"], name: "index_pasela_esongs_on_esong_key"
    t.index ["name_id"], name: "index_pasela_esongs_on_name_id"
    t.index ["ruby_id"], name: "index_pasela_esongs_on_ruby_id"
    t.index ["updated_at"], name: "index_pasela_esongs_on_updated_at"
  end

  create_table "versions", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.datetime "created_at", precision: nil
    t.string "event", null: false
    t.uuid "item_id", null: false
    t.string "item_type", null: false
    t.jsonb "object"
    t.jsonb "object_changes"
    t.string "whodunnit"
    t.index ["item_type", "item_id"], name: "index_versions_on_item_type_and_item_id"
  end

  add_foreign_key "pasela_artists", "istrings", column: "artist_name_id"
  add_foreign_key "pasela_esong_pasela_artists", "pasela_artists", column: "artist_id"
  add_foreign_key "pasela_esong_pasela_artists", "pasela_esongs", column: "song_id"
  add_foreign_key "pasela_esongs", "istrings", column: "name_id"
  add_foreign_key "pasela_esongs", "istrings", column: "ruby_id"
end
