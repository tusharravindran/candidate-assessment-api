class HardenResultDetailIndexes < ActiveRecord::Migration[7.1]
  def change
    remove_index :result_details, [:result_id, :question_id]
    add_index :result_details, [:result_id, :question_id], unique: true
  end
end
