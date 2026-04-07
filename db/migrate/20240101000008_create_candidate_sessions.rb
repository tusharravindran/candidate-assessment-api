class CreateCandidateSessions < ActiveRecord::Migration[7.1]
  def change
    create_table :candidate_sessions do |t|
      t.references :invitation, null: false, foreign_key: true, index: false
      t.references :organization, null: false, foreign_key: true
      t.references :assessment, null: false, foreign_key: true
      t.string :status, null: false, default: "not_started"
      t.datetime :started_at
      t.datetime :submitted_at
      t.datetime :deadline_at
      t.string :ip_address
      t.string :user_agent
      t.timestamps
    end
    add_index :candidate_sessions, [:organization_id, :status]
    add_index :candidate_sessions, :invitation_id, unique: true
  end
end
