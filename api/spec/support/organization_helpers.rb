# frozen_string_literal: true

# Runs spec code inside an organization's tenant context, the same way
# TenantResolverMiddleware sets Current for a real request.
#
#   before { @organization = create(:organization) }
#
#   it 'scopes to the tenant' do
#     within_organization do
#       ...
#     end
#   end
#
# Pass an organization explicitly to act as a different tenant:
#   within_organization(other_organization) { ... }
module OrganizationHelpers
  def within_organization(organization = @organization, &block)
    if organization.nil?
      raise ArgumentError, 'within_organization needs an organization (set @organization or pass one)'
    end

    Current.using(organization: organization, tenant_id: organization.id, &block)
  end
end

RSpec.configure do |config|
  config.include OrganizationHelpers
end
