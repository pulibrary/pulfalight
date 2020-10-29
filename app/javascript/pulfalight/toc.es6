export default class TocBuilder {
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
      window.location = location
    })
    this.element.on('ready.jstree', (e, data) => {
      const selectedId = this.element.jstree().get_selected()[0]
      const selectedElement = $(`#${selectedId}`)
      const scrollOffset = selectedElement.offset().top - selectedElement.offsetParent().offset().top - 60
      this.element.scrollTop(scrollOffset)
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
