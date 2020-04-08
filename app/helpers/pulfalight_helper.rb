# frozen_string_literal: true
module PulfalightHelper
  # Retrieves the current year
  # @return [Integer]
  def current_year
    DateTime.current.year
  end

  def repository_config_present(_, document)
    document.repository_config.present?
  end

  def request_config_present(var, document)
    repository_config_present(var, document) &&
      document.repository_config.request_config_present?
  end

  # Is this need?
  def document
    @document
  end

  def aeon_external_request
    document.build_external_request(presenter: show_presenter(document))
  end
end
