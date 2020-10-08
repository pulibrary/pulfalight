# frozen_string_literal: true

# Overrides to Arclight helper methods
module HelperOverrides
  def grouped?
    # Do not group if faceting by collection
    return false if search_state && facet_field_in_params?("collection_sim")
    try(:search_state) && search_state.params_for_search.try(:[], "group") == "true"
  end
end

ArclightHelper.include(HelperOverrides)
