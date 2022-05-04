# frozen_string_literal: true
class ReportHarmfulLanguageForm
  include ActiveModel::Model
  attr_accessor :name, :email, :box_number, :message, :location_code, :context

  validates :message, presence: true
  validates :email, email: true, allow_blank: true

  def submit
    ContactMailer.with(form: self).report.deliver
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
