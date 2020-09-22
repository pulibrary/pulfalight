# frozen_string_literal: true

# Add custom field accessors
Arclight::Engine.config.catalog_controller_field_accessors += %i[abstract_field collection_description_field collection_history_field]
