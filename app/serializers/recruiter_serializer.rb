class RecruiterSerializer < Blueprinter::Base
  identifier :id
  fields :email, :name, :role, :created_at
  association :organization, blueprint: OrganizationSerializer
end
