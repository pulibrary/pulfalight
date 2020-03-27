# frozen_string_literal: true
module PulfalightHelper

  # This overrides the context navigation helper functionality
  def generic_context_navigation(document, original_parents: document.parent_ids, component_level: 1)
    content_tag(
      :'document-navigator',
      '',
      id: 'document-navigator',
      ':document': document.navigation_tree.to_json
    )
  end
end
