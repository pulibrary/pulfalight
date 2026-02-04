# frozen_string_literal: true
class ContactMailer < ApplicationMailer
  # We only need the mailer if the collection has an
  # Engineering Library location, otherwise the messaging is handled
  # with the LibAnswers API
  # @see https://github.com/pulibrary/pulfalight/issues/1639
  def suggest
    @form = params[:form_class].new(params[:form_params])
    from = @form.email.presence || default_params[:from]
    mail(to: "wdressel@princeton.edu", from: from, subject: @form.email_subject)
  end

  def contact
    @form = params[:form_class].new(params[:form_params])
    mail(to: "wdressel@princeton.edu", from: @form.email, subject: @form.email_subject)
  end
end
