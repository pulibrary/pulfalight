# frozen_string_literal: true
class SuggestACorrectionForm
  include ActiveModel::Model
  attr_accessor :name, :email, :box_number, :message, :location_code, :context

  validates :name, :email, :message, presence: true
  validates :email, email: true

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
    "suggestacorrection@princeton.libanswers.com"
  end
end
