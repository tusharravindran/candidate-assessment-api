class ApplicationJob < ActiveJob::Base
  retry_on StandardError, wait: :polynomially_longer, attempts: 3

  def with_organization(organization_id)
    organization = Organization.find(organization_id)

    Current.set(organization: organization) do
      yield
    end
  end
end
