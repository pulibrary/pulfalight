# frozen_string_literal: true
class ContactMailer < ApplicationMailer
  def suggest
    @form = params[:form_class].new(params[:form_params])
    from = @form.email.presence || default_params[:from]
    mail(to: @form.routed_mail_to, from: from, subject: "Suggest a Correction")
  end

  def contact
    @form = params[:form_class].new(params[:form_params])
    mail(to: @form.routed_mail_to, from: @form.email, subject: @form.email_subject)
  end
end
