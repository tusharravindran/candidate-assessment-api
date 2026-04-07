class InvitationSerializer < Blueprinter::Base
  identifier :id
  fields :candidate_email, :candidate_name, :token, :expires_at, :used, :created_at
  association :assessment, blueprint: AssessmentSerializer

  field :invitation_url do |invitation|
    frontend_origin = ENV.fetch("FRONTEND_URL", "http://localhost:3000").split(",").first
    "#{frontend_origin}/candidate/#{invitation.token}"
  end

  view :candidate do
    fields :candidate_email, :candidate_name, :expires_at
  end
end
