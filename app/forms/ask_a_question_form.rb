# frozen_string_literal: true
class AskAQuestionForm
  include ActiveModel::Model
  attr_accessor :name, :email, :subject, :message, :location_code, :context, :title

  validates :name, :email, :message, presence: true
  validates :email, email: true

  def email_subject
    "[PULFA] #{subject_string}"
  end

  def subject_string
    return title if subject == "collection"
    subject
  end

  def subject_options
    [
      ["This Collection", "collection"],
      ["Reproductions & Photocopies", "reproduction"],
      ["Rights & Permissions", "permission"],
      ["Access", "access"],
      ["Other", "how much"]
    ]
  end

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

  def set_form_submitted
    @submitted = true
    @name = ""
    @email = ""
    @message = ""
  end

  def submitted?
    @submitted == true
  end

  def use_email?
    ["eng", "engineering library"].include? location_code
  end

  def serialize_params
    as_json.except("validation_context", "errors")
  end
end
