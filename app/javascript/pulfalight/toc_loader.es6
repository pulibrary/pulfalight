import TocBuilder from "../pulfalight/toc.es6"

export default class TocLoader {
  run() {
    this.setup_toc()
    this.setup_before_visit_listenter()
    this.setup_turbolinks_load_listener()
  }

  // The before-visit event only fires when a Turbolinks-enabled link is clicked
  setup_before_visit_listenter() {
    document.addEventListener('turbolinks:before-visit', () => {
      // We do NOT want to rebuild the table of contents when a link is clicked.
      // Provides a better user experience and reduces the number of AJAX requests.
      window.buildToc = false
    })
  }

  // Setup table of contents on initial page load
  setup_toc() {
    document.addEventListener('DOMContentLoaded', () => {
      const toc = new TocBuilder('#toc')
      toc.build()
      // Set initial toc build flag
      window.buildToc = true
    })
  }

  // Add listener for event that fires after turbolinks loads page
  // We DO want to rebuild the table of contents if navigating via history API.
  // Otherwise, the nodes on the tree are stale.
  setup_turbolinks_load_listener() {
    document.addEventListener('turbolinks:load', () => {
      if(window.buildToc) {
        // Remove existing tree
        $('#toc').jstree('destroy').empty()
        // Build new tree
        const toc = new TocBuilder('#toc')
        toc.build()
      } else {
        // Reset the toc build flag
        window.buildToc = true
      }
    })
  }
}
