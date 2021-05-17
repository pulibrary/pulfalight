# frozen_string_literal: true
class ApplicationController < ActionController::Base
  # Adds a few additional behaviors into the application controller
  include Blacklight::Controller
  layout :determine_layout

  def guest_uid_authentication_key(key)
    key &&= nil unless /^guest/.match?(key.to_s)
    return key if key
    "guest_" + guest_user_unique_suffix
  end

  def route_not_found
    render file: Rails.public_path.join("404.html"), status: :not_found, layout: false
  end
end
