# frozen_string_literal: true
module PulfalightHelper

  # This overrides the context navigation helper functionality
  # foo
  def generic_context_navigation(document, original_parents: document.parent_ids, component_level: 1)
    content_tag(
      :div,
      '',
      class: 'context-navigator',
      data: {
        collapse: I18n.t('arclight.views.show.collapse'),
        expand: I18n.t('arclight.views.show.expand'),
        arclight: {
          level: component_level,
          path: search_catalog_path(hierarchy_context: 'component'),
          name: document.collection_name,
          originalDocument: document.id,
          originalParents: original_parents,
          eadid: document.eadid
        }
      }
    )

    content_tag(
      :'document-navigator',
      '',
      id: 'document-navigator',
      '@document': document.to_json
    )
  end
end
