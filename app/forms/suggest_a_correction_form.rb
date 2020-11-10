# frozen_string_literal: true
class SuggestACorrectionForm
  include ActiveModel::Model
  attr_accessor :name, :email, :box_number, :message, :location_code, :context

  validates :name, :email, :message, presence: true

  def submit
    ContactMailer.with(form: self).suggest.deliver
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
    case location_code
    when "mss", "cotsen", "eng", "lae", "ga", "rarebooks", "selectors"
      "mssdiv@princeton.edu"
    when "mudd", "publicpolicy", "univarchives"
      "muddts@princeton.edu"
    when "rbsc"
      "rbsc@princeton.edu"
    when "engineering library"
      "wdressel@princeton.edu"
    end
  end
end
