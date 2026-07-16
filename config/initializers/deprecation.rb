# frozen_string_literal: true
Rails.application.config.after_initialize do
  # Silence Blacklight deprecation warnings.
  # Remove if needed for upgrading.
  Deprecation.default_deprecation_behavior = :silence
end
