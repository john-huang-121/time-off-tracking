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

ActiveRecord::Schema[8.0].define(version: 2026_02_12_015158) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "approvals", force: :cascade do |t|
    t.integer "decision", null: false
    t.text "comment"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "time_off_request_id", null: false
    t.bigint "reviewer_id", null: false
    t.index ["reviewer_id"], name: "index_approvals_on_reviewer_id"
    t.index ["time_off_request_id", "created_at"], name: "index_approvals_on_time_off_request_id_and_created_at"
    t.index ["time_off_request_id"], name: "index_approvals_on_time_off_request_id"
    t.check_constraint "decision = ANY (ARRAY[0, 1])", name: "chk_approvals_decision"
  end

  create_table "departments", force: :cascade do |t|
    t.string "name", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["name"], name: "index_departments_on_name", unique: true
  end

  create_table "profiles", force: :cascade do |t|
    t.string "first_name"
    t.string "last_name"
    t.date "birth_date"
    t.string "phone_number"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.bigint "department_id", null: false
    t.bigint "manager_id"
    t.index ["department_id"], name: "index_profiles_on_department_id"
    t.index ["manager_id"], name: "index_profiles_on_manager_id"
    t.index ["user_id"], name: "index_profiles_on_user_id", unique: true
  end

  create_table "time_off_requests", force: :cascade do |t|
    t.date "start_date", null: false
    t.date "end_date", null: false
    t.integer "time_off_type", default: 0, null: false
    t.integer "status", default: 0, null: false
    t.text "reason"
    t.integer "lock_version", default: 0, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["status"], name: "index_time_off_requests_on_status"
    t.index ["user_id", "start_date", "end_date"], name: "index_time_off_requests_on_user_id_and_start_date_and_end_date"
    t.index ["user_id"], name: "index_time_off_requests_on_user_id"
    t.check_constraint "start_date <= end_date", name: "chk_time_off_requests_date_range"
    t.check_constraint "status = ANY (ARRAY[0, 1, 2, 3])", name: "chk_time_off_requests_status"
    t.check_constraint "time_off_type = ANY (ARRAY[0, 1, 2])", name: "chk_time_off_requests_time_off_type"
  end

  create_table "users", force: :cascade do |t|
    t.integer "role", default: 0, null: false
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.integer "sign_in_count", default: 0, null: false
    t.datetime "current_sign_in_at"
    t.datetime "last_sign_in_at"
    t.string "current_sign_in_ip"
    t.string "last_sign_in_ip"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
    t.check_constraint "role = ANY (ARRAY[0, 1, 2])", name: "chk_users_role"
  end

  add_foreign_key "approvals", "time_off_requests"
  add_foreign_key "approvals", "users", column: "reviewer_id"
  add_foreign_key "profiles", "departments"
  add_foreign_key "profiles", "users"
  add_foreign_key "profiles", "users", column: "manager_id"
  add_foreign_key "time_off_requests", "users"
end
