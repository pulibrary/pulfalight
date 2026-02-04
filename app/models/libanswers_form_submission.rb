# frozen_string_literal: true
# This class is responsible for conveying a
# form submission to the libanswers API,
# which will create a ticket for Finding Aids staff to answer
class LibanswersFormSubmission
  class ApiSubmissionError < StandardError; end
  attr_reader :form

  def initialize(form_params:, form_class:)
    @form = deserialize_form(form_params, form_class)
  end

  def deserialize_form(form_params, form_class)
    form_class.new(form_params)
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
      quid: queue_id,
      pquestion: form.email_subject,
      pdetails: message,
      pname: form.name,
      pemail: form.email,
      ua: form.try(:user_agent)
    }.compact
  end

  def queue_id
    form_lookup = form.class.to_s.underscore.to_sym
    Rails.application.config_for(:config)[form_lookup][:queue_id]
  end

  def message
    return "#{@form.message}\n\nSent from #{form.context} via LibAnswers API" if form.context

    "#{@form.message}\n\nSent via LibAnswers API"
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
