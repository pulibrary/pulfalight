# frozen_string_literal: true
module AspaceStubbing
  def stub_aspace_login
    stub_request(:post, "https://aspace.test.org/staff/api/users/test/login?password=password").to_return(status: 200, body: { session: "1" }.to_json, headers: { "Content-Type": "application/json" })
  end

  def stub_aspace_ead(resource_descriptions_uri:, ead:)
    stub_request(:get, "https://aspace.test.org/staff/api/#{resource_descriptions_uri}.xml?include_daos=true&include_unpublished=false")
      .to_return(status: 200, body: File.open(Rails.root.join("spec", "fixtures", "aspace", ead)))
  end
end

RSpec.configure do |config|
  config.include AspaceStubbing
end
