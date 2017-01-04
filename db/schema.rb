# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your
# database schema. If you need to create the application database on another
# system, you should be using db:schema:load, not running all the migrations
# from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 20170103150435) do

  create_table "backups", force: :cascade do |t|
    t.integer  "tsserver_id", null: false
    t.text     "data",        null: false
    t.datetime "created_at",  null: false
    t.datetime "updated_at",  null: false
    t.index [nil], name: "index_backups_on_ts_id"
  end

  create_table "tsservers", force: :cascade do |t|
    t.integer  "port",                        null: false
    t.string   "dns"
    t.integer  "slots",                       null: false
    t.date     "time_payment",                null: false
    t.integer  "user_id",                     null: false
    t.integer  "machine_id",                  null: false
    t.datetime "created_at",                  null: false
    t.datetime "updated_at",                  null: false
    t.boolean  "state",        default: true
    t.index ["user_id"], name: "index_tsservers_on_user_id"
  end

  create_table "users", force: :cascade do |t|
    t.string   "email",                  default: "",   null: false
    t.string   "encrypted_password",     default: "",   null: false
    t.string   "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.integer  "sign_in_count",          default: 0,    null: false
    t.datetime "current_sign_in_at"
    t.datetime "last_sign_in_at"
    t.string   "current_sign_in_ip"
    t.string   "last_sign_in_ip"
    t.float    "money",                  default: 0.0
    t.datetime "created_at",                            null: false
    t.datetime "updated_at",                            null: false
    t.float    "spent",                  default: 0.0
    t.boolean  "auto_extension",         default: true
    t.integer  "ref",                    default: 0
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
  end

end
