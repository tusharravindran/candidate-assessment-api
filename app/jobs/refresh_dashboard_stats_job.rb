class RefreshDashboardStatsJob < ApplicationJob
  queue_as :low

  def perform(organization_id:)
    with_organization(organization_id) do
      Rails.cache.write(
        "organization:#{organization_id}:dashboard_stats_refreshed_at",
        Time.current.iso8601,
        expires_in: 6.hours
      )
    end
  end
end
