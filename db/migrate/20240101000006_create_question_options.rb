class CreateQuestionOptions < ActiveRecord::Migration[7.1]
  def change
    create_table :question_options do |t|
      t.references :question, null: false, foreign_key: true
      t.string :body, null: false
      t.boolean :correct, default: false
      t.integer :position, default: 0
      t.timestamps
    end
  end
end
