class AddJtiToRecruiters < ActiveRecord::Migration[7.1]
  def change
    add_column :recruiters, :jti, :string, null: false, default: ""
    add_index :recruiters, :jti, unique: true
  end
end
