class TocBuilder {
  constructor(element) {
    this.element = $(element)
    // We need a separate data element that is updated by turbolinks so we always
    // have the correct selected node id. The toc element itself is permanent (not
    // updated by turbolinks), and is instead updated by event-triggered javascript.
    this.dataElement = $(`${element}-data`)
  }

  get baseUrl() {
    return '/toc/'
  }

  get initialUrl() {
    return `${this.baseUrl}?node=${this.selectedId}&full=true`
  }

  get selectedId() {
    return this.dataElement.data('selected')
  }

  build() {
    this.setupTree()
    this.setupEventHandlers()
  }

  setupEventHandlers() {
    // Listen for click on the leaf node and follow link to component
    this.element.on('activate_node.jstree', function (e, data) {
      let location = `/catalog/${data.node.id}`
      Turbolinks.visit(location)
      // Scroll to top of page instead of jumping for better user experience
      window.scrollTo({ top: 0, behavior: 'smooth' });
    })
  }

  setupTree() {
    const that = this
    this.element.jstree({
      'core': {
        'themes': {
          'icons': false,
          'dots': false
        },
        'data' : {
          'url': function (node) {
            if (node.id === '#') {
              return that.initialUrl
            } else {
              return `${that.baseUrl}?node=${node.id}`
            }
          }
        }
      }
    });
  }
}


// Setup table of contents on initial page load
$(document).ready(function() {
  const toc = new TocBuilder('#toc')
  toc.build()
  // Set initial toc build flag
  window.buildToc = true
})

// The before-visit event only fires when a Turbolinks-enabled link is clicked
document.addEventListener('turbolinks:before-visit', function() {
  // We do not want to rebuild the table of contents when a link is clicked.
  // Provides a better user experience and reduces the number of AJAX requests.
  window.buildToc = false
})

// Add listener for event that fires after turbolinks loads page
document.addEventListener('turbolinks:load', function() {
  // Rebuild table of contents if navigating via history API
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
