class CreateResults < ActiveRecord::Migration[7.1]
  def change
    create_table :results do |t|
      t.references :candidate_session, null: false, foreign_key: true, index: false
      t.references :organization, null: false, foreign_key: true
      t.references :assessment, null: false, foreign_key: true
      t.integer :total_score, default: 0
      t.integer :max_score, default: 0
      t.decimal :percentage, precision: 5, scale: 2, default: 0
      t.boolean :passed, default: false
      t.boolean :pending_manual_review, default: false
      t.string :status, default: "pending"
      t.timestamps
    end
    add_index :results, :candidate_session_id, unique: true
    add_index :results, [:organization_id, :passed]
    add_index :results, :pending_manual_review
  end
end
