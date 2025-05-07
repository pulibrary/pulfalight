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

  RESCUE_WITH_404 = [
    ActionController::RoutingError
  ].freeze

  RESCUE_WITH_500 = [
    ArchivesSpace::ConnectionError
  ].freeze

  rescue_from(*RESCUE_WITH_404) do |e|
    if e.message == "xml export error"
      render xml: "<error>Not found</error>", status: :not_found, layout: false
    else
      route_not_found
    end
  end

  rescue_from(*RESCUE_WITH_500) do |e|
    if e.message == "xml export error"
      render xml: "<error>Server Error</error>", status: :internal_server_error, layout: false
    else
      render file: Rails.public_path.join("500.html"), status: :internal_server_error, layout: false
    end
  end

  def route_not_found
    render file: Rails.public_path.join("404.html"), status: :not_found, layout: false
  end
end
