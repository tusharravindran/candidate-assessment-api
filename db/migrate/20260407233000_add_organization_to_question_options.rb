class AddOrganizationToQuestionOptions < ActiveRecord::Migration[7.1]
  def up
    add_reference :question_options, :organization, foreign_key: true, index: false

    execute <<~SQL.squish
      UPDATE question_options
      SET organization_id = questions.organization_id
      FROM questions
      WHERE question_options.question_id = questions.id
    SQL

    change_column_null :question_options, :organization_id, false
    add_index :question_options, :organization_id
  end

  def down
    remove_index :question_options, :organization_id
    remove_reference :question_options, :organization, foreign_key: true
  end
end
