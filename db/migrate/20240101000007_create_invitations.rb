class CreateInvitations < ActiveRecord::Migration[7.1]
  def change
    create_table :invitations do |t|
      t.references :organization, null: false, foreign_key: true
      t.references :assessment, null: false, foreign_key: true
      t.references :recruiter, null: false, foreign_key: true
      t.string :candidate_email, null: false
      t.string :candidate_name
      t.string :token, null: false
      t.datetime :expires_at, null: false
      t.boolean :used, default: false
      t.timestamps
    end
    add_index :invitations, :token, unique: true
    add_index :invitations, [:organization_id, :candidate_email]
    add_index :invitations, :expires_at
  end
end
