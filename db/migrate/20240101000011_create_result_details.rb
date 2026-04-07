class CreateResultDetails < ActiveRecord::Migration[7.1]
  def change
    create_table :result_details do |t|
      t.references :result, null: false, foreign_key: true
      t.references :question, null: false, foreign_key: true
      t.references :organization, null: false, foreign_key: true
      t.text :candidate_answer
      t.text :expected_answer
      t.integer :score_awarded, default: 0
      t.integer :max_score, default: 0
      t.string :review_status, default: "not_required"
      t.text :reviewer_notes
      t.timestamps
    end
    add_index :result_details, [:result_id, :question_id]
  end
end
