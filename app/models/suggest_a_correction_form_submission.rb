# frozen_string_literal: true
# This class is responsible for conveying a
# form submission to the libanswers API,
# which will create a ticket for Finding Aids staff to answer
class SuggestACorrectionFormSubmission
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
    Net::HTTP.post uri, body, { Authorization: "Bearer #{token}" }
  end

    private

  attr_reader :name, :email, :box_number, :location_code, :context, :user_agent

  def body
    @body ||= data.to_a.map { |entry| "#{entry[0]}=#{entry[1]}" }.join("&")
  end

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
    @uri ||= URI("https://faq.library.princeton.edu/api/1.1/ticket/create")
  end

  def token
    @token ||= OAuthToken.find_or_create_by({ service: "libanswers",
                                              endpoint: "https://faq.library.princeton.edu/api/1.1/oauth/token" }).token
  end
end
