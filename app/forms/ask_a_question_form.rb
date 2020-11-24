# frozen_string_literal: true
class AskAQuestionForm
  include ActiveModel::Model
  attr_accessor :name, :email, :subject, :message, :location_code, :context, :title

  validates :name, :email, :message, presence: true
  validates :email, email: true

  # def submit
  #   ContactMailer.with(form: self).suggest.deliver
  #   @submitted = true
  #   @name = ""
  #   @email = ""
  #   @message = ""
  #   @box_number = ""
  # end
  #
  # def submitted?
  #   @submitted == true
  # end

  def routed_mail_to
    case location_code
    when "rbsc", "lae", "mss", "rarebooks"
      "rbsc@princeton.edu"
    when "mudd", "publicpolicy", "univarchives"
      "mudd@princeton.edu"
    when "engineering library", "eng"
      "wdressel@princeton.edu"
    when "ga"
      "jmellby@princeton.edu"
    end
  end
end
