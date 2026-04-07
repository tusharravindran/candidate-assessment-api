class OrganizationSerializer < Blueprinter::Base
  identifier :id
  fields :name, :slug, :plan, :created_at
end
