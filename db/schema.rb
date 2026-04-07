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

ActiveRecord::Schema[7.1].define(version: 2026_04_07_233000) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "answers", force: :cascade do |t|
    t.bigint "candidate_session_id", null: false
    t.bigint "question_id", null: false
    t.bigint "organization_id", null: false
    t.text "free_text_answer"
    t.integer "selected_option_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["candidate_session_id", "question_id"], name: "index_answers_on_candidate_session_id_and_question_id", unique: true
    t.index ["candidate_session_id"], name: "index_answers_on_candidate_session_id"
    t.index ["organization_id"], name: "index_answers_on_organization_id"
    t.index ["question_id"], name: "index_answers_on_question_id"
  end

  create_table "assessments", force: :cascade do |t|
    t.bigint "organization_id", null: false
    t.bigint "recruiter_id", null: false
    t.string "title", null: false
    t.text "description"
    t.integer "time_limit_minutes", default: 60
    t.integer "passing_score", default: 70
    t.string "status", default: "draft", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["organization_id", "status"], name: "index_assessments_on_organization_id_and_status"
    t.index ["organization_id"], name: "index_assessments_on_organization_id"
    t.index ["recruiter_id"], name: "index_assessments_on_recruiter_id"
    t.index ["status"], name: "index_assessments_on_status"
  end

  create_table "candidate_sessions", force: :cascade do |t|
    t.bigint "invitation_id", null: false
    t.bigint "organization_id", null: false
    t.bigint "assessment_id", null: false
    t.string "status", default: "not_started", null: false
    t.datetime "started_at"
    t.datetime "submitted_at"
    t.datetime "deadline_at"
    t.string "ip_address"
    t.string "user_agent"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["assessment_id"], name: "index_candidate_sessions_on_assessment_id"
    t.index ["invitation_id"], name: "index_candidate_sessions_on_invitation_id", unique: true
    t.index ["organization_id", "status"], name: "index_candidate_sessions_on_organization_id_and_status"
    t.index ["organization_id"], name: "index_candidate_sessions_on_organization_id"
  end

  create_table "invitations", force: :cascade do |t|
    t.bigint "organization_id", null: false
    t.bigint "assessment_id", null: false
    t.bigint "recruiter_id", null: false
    t.string "candidate_email", null: false
    t.string "candidate_name"
    t.string "token", null: false
    t.datetime "expires_at", null: false
    t.boolean "used", default: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["assessment_id"], name: "index_invitations_on_assessment_id"
    t.index ["expires_at"], name: "index_invitations_on_expires_at"
    t.index ["organization_id", "candidate_email"], name: "index_invitations_on_organization_id_and_candidate_email"
    t.index ["organization_id"], name: "index_invitations_on_organization_id"
    t.index ["recruiter_id"], name: "index_invitations_on_recruiter_id"
    t.index ["token"], name: "index_invitations_on_token", unique: true
  end

  create_table "jwt_denylist", force: :cascade do |t|
    t.string "jti", null: false
    t.datetime "exp", null: false
    t.index ["jti"], name: "index_jwt_denylist_on_jti"
  end

  create_table "organizations", force: :cascade do |t|
    t.string "name", null: false
    t.string "slug", null: false
    t.string "plan", default: "free"
    t.jsonb "settings", default: {}
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["slug"], name: "index_organizations_on_slug", unique: true
  end

  create_table "question_options", force: :cascade do |t|
    t.bigint "question_id", null: false
    t.string "body", null: false
    t.boolean "correct", default: false
    t.integer "position", default: 0
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "organization_id", null: false
    t.index ["organization_id"], name: "index_question_options_on_organization_id"
    t.index ["question_id"], name: "index_question_options_on_question_id"
  end

  create_table "questions", force: :cascade do |t|
    t.bigint "assessment_id", null: false
    t.bigint "organization_id", null: false
    t.text "body", null: false
    t.string "question_type", null: false
    t.integer "points", default: 1
    t.integer "position", default: 0
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["assessment_id", "position"], name: "index_questions_on_assessment_id_and_position"
    t.index ["assessment_id"], name: "index_questions_on_assessment_id"
    t.index ["organization_id"], name: "index_questions_on_organization_id"
  end

  create_table "recruiters", force: :cascade do |t|
    t.string "email", null: false
    t.string "encrypted_password", null: false
    t.string "name"
    t.bigint "organization_id", null: false
    t.string "role", default: "member"
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
    t.string "jti", default: "", null: false
    t.index ["email"], name: "index_recruiters_on_email", unique: true
    t.index ["jti"], name: "index_recruiters_on_jti", unique: true
    t.index ["organization_id"], name: "index_recruiters_on_organization_id"
    t.index ["reset_password_token"], name: "index_recruiters_on_reset_password_token", unique: true
  end

  create_table "result_details", force: :cascade do |t|
    t.bigint "result_id", null: false
    t.bigint "question_id", null: false
    t.bigint "organization_id", null: false
    t.text "candidate_answer"
    t.text "expected_answer"
    t.integer "score_awarded", default: 0
    t.integer "max_score", default: 0
    t.string "review_status", default: "not_required"
    t.text "reviewer_notes"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["organization_id"], name: "index_result_details_on_organization_id"
    t.index ["question_id"], name: "index_result_details_on_question_id"
    t.index ["result_id", "question_id"], name: "index_result_details_on_result_id_and_question_id", unique: true
    t.index ["result_id"], name: "index_result_details_on_result_id"
  end

  create_table "results", force: :cascade do |t|
    t.bigint "candidate_session_id", null: false
    t.bigint "organization_id", null: false
    t.bigint "assessment_id", null: false
    t.integer "total_score", default: 0
    t.integer "max_score", default: 0
    t.decimal "percentage", precision: 5, scale: 2, default: "0.0"
    t.boolean "passed", default: false
    t.boolean "pending_manual_review", default: false
    t.string "status", default: "pending"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["assessment_id"], name: "index_results_on_assessment_id"
    t.index ["candidate_session_id"], name: "index_results_on_candidate_session_id", unique: true
    t.index ["organization_id", "passed"], name: "index_results_on_organization_id_and_passed"
    t.index ["organization_id"], name: "index_results_on_organization_id"
    t.index ["pending_manual_review"], name: "index_results_on_pending_manual_review"
  end

  add_foreign_key "answers", "candidate_sessions"
  add_foreign_key "answers", "organizations"
  add_foreign_key "answers", "questions"
  add_foreign_key "assessments", "organizations"
  add_foreign_key "assessments", "recruiters"
  add_foreign_key "candidate_sessions", "assessments"
  add_foreign_key "candidate_sessions", "invitations"
  add_foreign_key "candidate_sessions", "organizations"
  add_foreign_key "invitations", "assessments"
  add_foreign_key "invitations", "organizations"
  add_foreign_key "invitations", "recruiters"
  add_foreign_key "question_options", "organizations"
  add_foreign_key "question_options", "questions"
  add_foreign_key "questions", "assessments"
  add_foreign_key "questions", "organizations"
  add_foreign_key "recruiters", "organizations"
  add_foreign_key "result_details", "organizations"
  add_foreign_key "result_details", "questions"
  add_foreign_key "result_details", "results"
  add_foreign_key "results", "assessments"
  add_foreign_key "results", "candidate_sessions"
  add_foreign_key "results", "organizations"
end
