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
    stub_request(:post, "https://figgy.princeton.edu/resources/refresh_remote_metadata?auth_token=123456")
      .to_return(
        body: "",
        status: status_code
      )
  end

  def stub_libanswers_oauth
    stub_request(:post, "https://faq.library.princeton.edu/api/1.1/oauth/token")
      .with(body: "client_id=ABC&client_secret=12345&grant_type=client_credentials")
      .to_return(status: 200, body: file_fixture("libanswers/oauth_token.json"))
  end

  def stub_libanswers_oauth_invalid
    stub_request(:post, "https://faq.library.princeton.edu/api/1.1/oauth/token")
      .with(body: "client_id=ABC&client_secret=12345&grant_type=client_credentials")
      .to_return(status: 400, body: {error: "Incorrect format"}.to_json)
  end

  def stub_libanswers_api
    stub_request(:post, 'https://faq.library.princeton.edu/api/1.1/oauth/token')
      .with(body: 'client_id=ABC&client_secret=12345&grant_type=client_credentials')
      .to_return(status: 200, body: file_fixture('libanswers/oauth_token.json'))
    stub_request(:post, 'https://faq.library.princeton.edu/api/1.1/ticket/create')
  end

  def stub_libanswers_api_invalid
    stub_request(:post, 'https://faq.library.princeton.edu/api/1.1/oauth/token')
      .with(body: 'client_id=ABC&client_secret=12345&grant_type=client_credentials')
      .to_return(status: 200, body: file_fixture('libanswers/oauth_token.json'))
    stub_request(:post, "https://faq.library.princeton.edu/api/1.1/ticket/create")
      .to_return(status: 422, body: "Message can't be blank", headers: {})
  end
end

RSpec.configure do |config|
  config.include Stubbing
end
