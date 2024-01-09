# frozen_string_literal: true
class ContactMailer < ApplicationMailer
  def suggest
    @form = params[:form_class].new(params[:form_params])
    mail(to: @form.routed_mail_to, from: @form.email, subject: "Suggest a Correction")
  end

  def report
    @form = params[:form_class].new(params[:form_params])
    if @form.email.blank?
      mail(to: @form.routed_mail_to, from: "anonymous@princeton.edu", subject: "Reporting Harmful Language")
    else
      mail(to: @form.routed_mail_to, from: @form.email, subject: "Reporting Harmful Language")
    end
  end

  def contact
    @form = params[:form_class].new(params[:form_params])
    mail(to: @form.routed_mail_to, from: @form.email, subject: @form.email_subject)
  end
end
