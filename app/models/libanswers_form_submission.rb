# frozen_string_literal: true
# This class is responsible for conveying a
# form submission to the libanswers API,
# which will create a ticket for Finding Aids staff to answer
class SuggestACorrectionFormSubmission
  class ApiSubmissionError < StandardError; end
  attr_reader :name, :email, :box_number, :location_code, :context, :user_agent
  # rubocop:disable Metrics/ParameterLists
  def initialize(message:, name:, email:, box_number:, location_code:, context:, user_agent:)
    @message = message
    @name = name
    @email = email
    @user_agent = user_agent
    @context = context
    @box_number = box_number
    @location_code = location_code
  end

  def send_to_libanswers
    http = Net::HTTP.new uri.host, uri.port
    http.use_ssl = true
    request = Net::HTTP::Post.new(
      uri.path, {
        "Content-Type" => "application/x-www-form-urlencoded",
        "Authorization" => "Bearer #{token}"
      }
    )
    request.set_form_data(data)
    response = http.request(request)
    raise ApiSubmissionError unless response.code == "200"
    response
  end

    private

  def data
    {
      quid: Rails.application.config_for(:config)[:suggest_a_correction_form][:queue_id],
      pquestion: "Finding Aids Suggest a Correction Form",
      pdetails: message,
      pname: name,
      pemail: email,
      ua: user_agent
    }.compact
  end

  def message
    return "#{@message}\n\nSent from #{context} via LibAnswers API" if context

    "#{@message}\n\nSent via LibAnswers API"
  end

  def uri
    URI("https://faq.library.princeton.edu/api/1.1/ticket/create")
  end

  def token
    OAuthToken.find_or_create_by(
      {
        service: "libanswers",
        endpoint: "https://faq.library.princeton.edu/api/1.1/oauth/token"
      }
    ).token
  end
end
