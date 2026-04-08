class InvitationSerializer < Blueprinter::Base
  identifier :id
  fields :candidate_email, :candidate_name, :token, :expires_at, :used, :created_at
  association :assessment, blueprint: AssessmentSerializer

  field :invitation_url do |invitation|
    frontend_origin = ENV.fetch("FRONTEND_URL", "http://localhost:3000").split(",").first
    "#{frontend_origin}/candidate/#{invitation.token}"
  end

  field :session_status do |invitation|
    invitation.candidate_session&.status || "not_started"
  end

  field :result_id do |invitation|
    invitation.candidate_session&.result&.id
  end

  field :score_percentage do |invitation|
    invitation.candidate_session&.result&.percentage
  end

  field :passed do |invitation|
    invitation.candidate_session&.result&.passed
  end

  view :candidate do
    fields :candidate_email, :candidate_name, :expires_at
  end
end
