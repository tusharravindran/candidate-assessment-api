class AddActiveAndDomainToOrganizations < ActiveRecord::Migration[7.1]
  def change
    add_column :organizations, :active, :boolean, default: true, null: false
    add_column :organizations, :domain, :string
    add_index  :organizations, :active
    add_index  :organizations, :domain, unique: true, where: "domain IS NOT NULL"
  end
end
