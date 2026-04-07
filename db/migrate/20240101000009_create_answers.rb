class CreateAnswers < ActiveRecord::Migration[7.1]
  def change
    create_table :answers do |t|
      t.references :candidate_session, null: false, foreign_key: true
      t.references :question, null: false, foreign_key: true
      t.references :organization, null: false, foreign_key: true
      t.text :free_text_answer
      t.integer :selected_option_id
      t.timestamps
    end
    add_index :answers, [:candidate_session_id, :question_id], unique: true
  end
end
