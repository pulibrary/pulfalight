# frozen_string_literal: true
class SuggestACorrectionForm
  include ActiveModel::Model
  attr_accessor :name, :email, :box_number, :message, :location_code, :context, :user_agent

  validates :message, presence: true
  validates :email, email: true, allow_blank: true

  def submit
    if use_email?
      ContactMailer.with(
        form_params: serialize_params,
        form_class: self.class
      ).suggest.deliver_later
    else
      LibanswersTicketJob.perform_later(
        form_params: serialize_params,
        form_class: self.class
      )
    end
    set_form_submitted
  end

  def serialize_params
    as_json.except("validation_context", "errors")
  end

  def submitted?
    @submitted == true
  end

  def use_email?
    ["engineering library"].include? location_code
  end

  def email_subject
    "Finding Aids Suggest a Correction Form"
  end

  private

  def set_form_submitted
    @submitted = true
    @name = ""
    @email = ""
    @message = ""
    @box_number = ""
  end
end
