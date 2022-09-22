# frozen_string_literal: true
module AspaceStubbing
  def stub_aspace_login
    stub_request(:post, "https://aspace.test.org/staff/api/users/test/login?password=secretpassword").to_return(status: 200, body: { session: "1" }.to_json, headers: { "Content-Type": "application/json" })
  end

  def stub_aspace_ead(resource_descriptions_uri:, ead:)
    stub_request(:get, "https://aspace.test.org/staff/api/#{resource_descriptions_uri}.xml?include_daos=true&include_unpublished=false")
      .to_return(status: 200, body: File.open(Rails.root.join("spec", "fixtures", "aspace", ead)))
  end

  def stub_aspace_repositories
    stub_request(:get, "https://aspace.test.org/staff/api/repositories?page=1")
      .to_return(status: 200, body: File.open(Rails.root.join("spec", "fixtures", "aspace", "repositories.json")), headers: { "Content-Type": "application/json" })
  end

  def stub_aspace_resource_ids(repository_id:, resource_ids:, modified_since: nil)
    url = "https://aspace.test.org/staff/api/repositories/#{repository_id}/resources?all_ids=true"
    url += "&modified_since=#{modified_since}" if modified_since
    stub_request(:get, url)
      .to_return(status: 200, body: resource_ids.to_json, headers: { "Content-Type": "application/json" })
    stub_search(repository_id: repository_id, resource_ids: resource_ids)
  end

  def stub_search(repository_id:, resource_ids:)
    resource_ids.flat_map do |resource_id|
      all_repository_ids.map do |curr_repo_id|
        if curr_repo_id == repository_id
          stub_request(:get, "https://aspace.test.org/staff/api/repositories/#{repository_id}/search?fields%5B%5D=identifier&fields%5B%5D=uri&page=1&q=identifier:#{resource_id}&type%5B%5D=resource")
            .to_return(status: 200, body: resource_response(repository_id, resource_id).to_json, headers: { "Content-Type": "application/json" })
        else
          stub_request(:get, "https://aspace.test.org/staff/api/repositories/#{curr_repo_id}/search?fields%5B%5D=identifier&fields%5B%5D=uri&page=1&q=identifier:#{resource_id}&type%5B%5D=resource")
            .to_return(status: 200, body: { results: [] }.to_json, headers: { "Content-Type": "application/json" })
        end
      end
    end
  end

  def all_repository_ids
    ["3", "13"]
  end

  def resource_response(repository_id, resource_id)
    {
      results: [
        { uri: "/repositories/#{repository_id}/resources/#{resource_id}", identifier: resource_id }
      ]
    }
  end
end

RSpec.configure do |config|
  config.include AspaceStubbing
end
