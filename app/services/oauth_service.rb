# frozen_string_literal: true

# This class is responsible for communicating with an
# OAuth server to get new access tokens
class OAuthService
  class CouldNotGenerateOAuthToken < StandardError; end
  attr_reader :endpoint, :service

  def initialize(endpoint:, service:)
    @endpoint = URI(endpoint)
    @service = service.to_sym
  end

  def new_token
    token = JSON.parse(response.body)["access_token"]
    raise CouldNotGenerateOAuthToken unless token
    token
  end

  def expiration_time
    validity_in_seconds = JSON.parse(response.body)["expires_in"]
    validity_in_seconds.seconds.from_now - 1.hour
  end

    private

  def client_id
    configuration[:client_id]
  end

  def client_secret
    configuration[:client_secret]
  end

  def response
    @response ||= Net::HTTP.post_form(endpoint, client_id: client_id, client_secret: client_secret, grant_type: grant_type)
  end

  def grant_type
    "client_credentials"
  end

  def configuration
    @configuration ||= Rails.application.config_for(:config)[service]
  end
end
