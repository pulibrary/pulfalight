# frozen_string_literal: true
class ApplicationMailer < ActionMailer::Base
  default from: "no-reply@#{ActionMailer::Base.default_url_options[:host]}"
  layout "mailer"
end
