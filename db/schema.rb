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

ActiveRecord::Schema.define(version: 2019_09_06_211203) do

  create_table "interactions", force: :cascade do |t|
    t.integer "user_id", null: false
    t.integer "proposal_id", null: false
    t.string "last_vote"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["proposal_id"], name: "index_interactions_on_proposal_id"
    t.index ["user_id"], name: "index_interactions_on_user_id"
  end

  create_table "proposals", force: :cascade do |t|
    t.integer "number", null: false
    t.string "state", null: false
    t.string "title", null: false
    t.integer "proposer_id", null: false
    t.datetime "opened_at", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["proposer_id"], name: "index_proposals_on_proposer_id"
  end

  create_table "users", force: :cascade do |t|
    t.string "login", null: false
    t.string "avatar_url"
    t.boolean "author", default: false, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "email"
    t.string "provider"
    t.string "uid"
    t.boolean "notify_new", default: true
  end

end
