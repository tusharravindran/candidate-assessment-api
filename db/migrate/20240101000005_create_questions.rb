class CreateQuestions < ActiveRecord::Migration[7.1]
  def change
    create_table :questions do |t|
      t.references :assessment, null: false, foreign_key: true
      t.references :organization, null: false, foreign_key: true
      t.text :body, null: false
      t.string :question_type, null: false
      t.integer :points, default: 1
      t.integer :position, default: 0
      t.timestamps
    end
    add_index :questions, [:assessment_id, :position]
    add_index :questions, :organization_id
  end
end
