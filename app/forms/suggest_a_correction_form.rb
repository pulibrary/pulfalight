# frozen_string_literal: true
class SuggestACorrectionForm
  include ActiveModel::Model
  attr_accessor :name, :email, :box_number, :message, :location_code, :context, :user_agent

  validates :message, presence: true
  validates :email, email: true, allow_blank: true

  def submit
    ContactMailer.with(form_params: as_json.except("validation_context", "errors"), form_class: self.class).suggest.deliver_later
    @submitted = true
    @name = ""
    @email = ""
    @message = ""
    @box_number = ""
  end

  def submitted?
    @submitted == true
  end

  def routed_mail_to
    return "wdressel@princeton.edu" if ["engineering library"].include?(location_code)
    SuggestACorrectionFormSubmission.new(
      message: message, name: name, email: email, box_number: box_number, location_code: location_code, context: context, user_agent: user_agent
    ).send_to_libanswers
  end
end
