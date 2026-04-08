namespace :results do
  desc "Backfill results for submitted sessions missing a result (optionally scoped to org_id)"
  task backfill: :environment do
    org_id = ENV["ORG_ID"]
    scope = CandidateSession.where(status: %w[submitted auto_submitted])
    scope = scope.where(organization_id: org_id) if org_id.present?

    missing = scope.left_outer_joins(:result).where(results: { id: nil })
    total = missing.count
    puts "Backfilling results for #{total} sessions..."

    missing.find_each do |session|
      Current.set(organization: session.organization) do
        ScoringService.new(session).call
        AggregateResultsJob.perform_now(candidate_session_id: session.id, organization_id: session.organization_id)
      end
    rescue StandardError => e
      warn "Failed session #{session.id}: #{e.class} #{e.message}"
    end

    puts "Done."
  end
end
