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

    if (this.getOnlineToggleParam()) {
      url = `${url}&online_content=true`
    }

    return url
  }

  get selectedId() {
    return this.dataElement.data('selected')
  }

  get toggleElement() {
    return document.getElementById('tocOnlineToggle')
  }

  setOnlineToggleParam(value) {
    let url = new URL(window.location.href)
    let params = new URLSearchParams(url.search)

    params.set('onlineToggle', value)

    url.search = params.toString()
    window.history.pushState({}, '', url)
  }

  getOnlineToggleParam() {
    const urlParams = new URLSearchParams(window.location.search);
    const paramValue = urlParams.get('onlineToggle') || 'false'
    if (paramValue === 'true') {
      return true
    } else {
      return false
    }
  }

  build() {
    if (this.element.length > 0) {
      this.setupToggleElement()
      this.setupTree()
      this.setupEventHandlers()
    }
  }

  setupToggleElement() {
    this.toggleElement.checked = this.getOnlineToggleParam()
  }

  setupEventHandlers() {
    // Listen for click on the leaf node and follow link to component
    this.element.on('activate_node.jstree', (e, data) => {
      let location = `/catalog/${data.node.id}?onlineToggle=${this.getOnlineToggleParam()}`
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
    this.toggleElement.addEventListener('change', (e) => {
      if(e.target.checked) {
        document.getElementById('toc-container').classList.add('online-only')
        this.setOnlineToggleParam(true)
        this.element.jstree("destroy");
        this.build()
      } else {
        document.getElementById('toc-container').classList.remove('online-only')
        this.setOnlineToggleParam(false)
        this.build()
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
              if (that.getOnlineToggleParam()) {
                url = `${url}&online_content=true`
              }
              return url
            }
          }
        }
      }
    });
  }
}
