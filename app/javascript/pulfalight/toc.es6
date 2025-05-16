export default class TocBuilder {
  constructor(element) {
    this.element = $(element)
    this.online_toggle_state = new Map()
    this.collection = null
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

    if (this.getOnlineToggleValue(this.collection)) {
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

  setOnlineToggleValue(collection, value) {
    var pulfalightOnlineToggleStates = localStorage.getItem('pulfalightOnlineToggleStates');
    this.online_toggle_state = new Map(JSON.parse(pulfalightOnlineToggleStates));
    this.online_toggle_state.set(collection, value)
    localStorage.setItem('pulfalightOnlineToggleStates', JSON.stringify([...this.online_toggle_state]));
  }

  getOnlineToggleValue(collection) {
    var pulfalightOnlineToggleStates = localStorage.getItem('pulfalightOnlineToggleStates');
    this.online_toggle_state = new Map(JSON.parse(pulfalightOnlineToggleStates));
    const value = this.online_toggle_state.get(collection)
    if (value === 'true') {
      return true
    } else {
      return false
    }
  }

  build() {
    if (this.element.length > 0) {
      this.setupTree()
      this.setupToggleElement()
      this.setupEventHandlers()
    }
  }

  setupToggleElement() {
    this.collection = $('#document').data('document-id').split("_").at(0)
    this.online_toggle_state.set(this.collection, 'false')
    const checked = this.getOnlineToggleValue(this.collection)
    this.toggleElement.checked = checked
    if (checked) {
      document.getElementById('toc-container').classList.add('online-only')
    } else {
      document.getElementById('toc-container').classList.remove('online-only')
    }
  }

  setupEventHandlers() {
    // Listen for click on the leaf node and follow link to component
    this.element.on('activate_node.jstree', (e, data) => {
      let location = `/catalog/${data.node.id}`
      window.location = location
    })
    this.element.on('ready.jstree', (e, data) => {
      const selectedId = this.element.jstree().get_selected()[0]
      const selectedElement = $(`#${selectedId}`)
      if (selectedElement.length > 0) {
        // Jump to selected element on page reload
        const scrollOffset = selectedElement.offset().top - selectedElement.offsetParent().offset().top - 130
        this.element.scrollTop(scrollOffset)
      }
    })
    this.toggleElement.addEventListener('change', (e) => {
      if(e.target.checked) {
        document.getElementById('toc-container').classList.add('online-only')
        this.setOnlineToggleValue(this.collection, 'true')
        this.element.jstree("destroy");
        this.build()
      } else {
        document.getElementById('toc-container').classList.remove('online-only')
        this.setOnlineToggleValue(this.collection, 'false')
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
              if (that.getOnlineToggleValue(that.collection)) {
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
