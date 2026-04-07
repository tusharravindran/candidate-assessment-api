class CreateAssessments < ActiveRecord::Migration[7.1]
  def change
    create_table :assessments do |t|
      t.references :organization, null: false, foreign_key: true
      t.references :recruiter, null: false, foreign_key: true
      t.string :title, null: false
      t.text :description
      t.integer :time_limit_minutes, default: 60
      t.integer :passing_score, default: 70
      t.string :status, null: false, default: "draft"
      t.timestamps
    end
    add_index :assessments, [:organization_id, :status]
    add_index :assessments, :status
  end
end
