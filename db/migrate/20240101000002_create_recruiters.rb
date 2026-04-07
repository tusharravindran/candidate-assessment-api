class CreateRecruiters < ActiveRecord::Migration[7.1]
  def change
    create_table :recruiters do |t|
      t.string :email, null: false
      t.string :encrypted_password, null: false
      t.string :name
      t.references :organization, null: false, foreign_key: true
      t.string :role, default: "member"
      # Devise fields
      t.string :reset_password_token
      t.datetime :reset_password_sent_at
      t.datetime :remember_created_at
      t.integer :sign_in_count, default: 0, null: false
      t.datetime :current_sign_in_at
      t.datetime :last_sign_in_at
      t.string :current_sign_in_ip
      t.string :last_sign_in_ip
      t.timestamps
    end
    add_index :recruiters, :email, unique: true
    add_index :recruiters, :reset_password_token, unique: true
  end
end
