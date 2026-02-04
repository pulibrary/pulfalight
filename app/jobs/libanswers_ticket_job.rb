# frozen_string_literal: true

class LibanswersTicketJob < ApplicationJob
  def perform(form_params:, form_class:)
    LibanswersFormSubmission.new(
      form_params: form_params,
      form_class: form_class
    ).send_to_libanswers
  end
end
