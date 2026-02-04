# frozen_string_literal: true
class SuggestACorrectionForm
  include ActiveModel::Model
  attr_accessor :name, :email, :box_number, :message, :location_code, :context, :user_agent

  validates :message, presence: true
  validates :email, email: true, allow_blank: true

  def submit
    if use_email?
      ContactMailer.with(form_params: as_json.except("validation_context", "errors"), form_class: self.class).suggest.deliver_later
    else
      LibanswersTicketJob.perform_later(
        message: message, name: name, email: email, box_number: box_number, location_code: location_code, context: context, user_agent: user_agent
      )
    end
    @submitted = true
    @name = ""
    @email = ""
    @message = ""
    @box_number = ""
  end

  def submitted?
    @submitted == true
  end

  def use_email?
    ["engineering library"].include? location_code
  end
end
