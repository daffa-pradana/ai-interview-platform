# frozen_string_literal: true

# Current.tenant_id / organization / user live in RequestStore, which is only
# cleared per HTTP request by its Rack middleware. Model and service specs never
# go through that middleware, so clear it around every example to stop tenant
# context leaking from one test into the next.
RSpec.configure do |config|
  config.before { RequestStore.clear! }
  config.after  { RequestStore.clear! }
end
