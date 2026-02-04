# frozen_string_literal: true

class LibanswersTicketJob < ApplicationJob
  # rubocop:disable Metrics/ParameterLists
  def perform(message:, name:, email:, box_number:, location_code:, context:, user_agent:)
    LibanswersFormSubmission.new(
      message: message, name: name, email: email, box_number: box_number, location_code: location_code, context: context, user_agent: user_agent
    ).send_to_libanswers
  end
  # rubocop:enable Metrics/ParameterLists
end
