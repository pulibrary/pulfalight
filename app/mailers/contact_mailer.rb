# frozen_string_literal: true
class ContactMailer < ApplicationMailer
  def suggest
    @form = params[:form]
    mail(to: @form.routed_mail_to, subject: "Suggest a Correction")
  end

  def contact
    @form = params[:form]
    mail(to: @form.routed_mail_to, subject: @form.email_subject)
  end
end
