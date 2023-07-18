export default class TocBuilder {
  constructor(element) {
    this.element = $(element)
    // We need a separate data element that is updated by turbolinks so we always
    // have the correct selected node id. The toc element itself is permanent (not
    // updated by turbolinks), and is instead updated by event-triggered javascript.
    this.dataElement = $(`${element}-data`)
  }

  get expanded() {
    return this.dataElement.data('expanded')
  }

  get baseUrl() {
    return '/toc'
  }

  get initialUrl() {
    let url = `${this.baseUrl}?node=${this.selectedId}&full=true`

    if (this.expanded) {
      url = `${url}&expanded=true`
    }

    return url
  }

  get selectedId() {
    return this.dataElement.data('selected')
  }

  build() {
    if (this.element.length > 0) {
      this.setupTree()
      this.setupEventHandlers()
    }
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
      if (selectedElement.length > 0) {
        // Jump to selected element on page reload
        const scrollOffset = selectedElement.offset().top - selectedElement.offsetParent().offset().top - 60
        this.element.scrollTop(scrollOffset)
      }
    })
    var state=localStorage.getItem("onlineOnly");
    if(state=="true"){
      document.getElementById('toc-container').classList.add('online-only')
      document.getElementById('tocOnlineToggle').checked = true;
    } else {
      document.getElementById('toc-container').classList.remove('online-only')
      document.getElementById('tocOnlineToggle').checked = false;
    }
    document.getElementById('tocOnlineToggle').addEventListener('change', (e) => {
      if(e.target.checked) {
        document.getElementById('toc-container').classList.add('online-only')
        localStorage.setItem("onlineOnly","true")
      } else {
        document.getElementById('toc-container').classList.remove('online-only')
        localStorage.setItem("onlineOnly","false")
      }
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
              let url = `${that.baseUrl}?node=${node.id}`
              if (that.expanded) {
                url = `${url}&expanded=true`
              }
              return url
            }
          }
        }
      }
    });
  }
}
