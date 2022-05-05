module Stubbing
  def stub_lib_cal(id:)
    stub_request(:get, "https://libcal.princeton.edu/api_hours_today.php?iid=771&lid=#{id}&format=json&systemTime=1")
      .to_return(
        body: file_fixture("libcal/#{id}.json").read,
        headers: {
          'Content-Type' => "application/json"
        }
      )
  end

  def stub_refresh_remote_metadata(status_code:)
    stub_request(:post, "https://figgy.princeton.edu/resources/refresh_remote_metadata")
      .to_return(
        body: "",
        status: status_code
      )
  end
end

RSpec.configure do |config|
  config.include Stubbing
end
