# frozen_string_literal: true
RSpec.configure do |config|
  config.before(:each) do
    client = Blacklight.default_index.connection
    client.delete_by_query("*:*", params: { softCommit: true })
  end
end
