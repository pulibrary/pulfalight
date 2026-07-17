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
      this.setupObservers()
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
        this.#scrollComponentToTop(selectedElement)
        // Make the parent element sticky so the user knows the context of the element
        selectedElement.get().forEach(element => this.#makeParentSticky(element))
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

  setupObservers() {
    function addObservers() {
      document.querySelectorAll('.jstree-leaf').forEach(leaf => observer.observe(leaf))
    }

    const scrollport = document.querySelector('#toc');
    const observer = new IntersectionObserver(
      entries => entries.forEach(entry => {
        if (entry.isIntersecting) {
          this.#makeParentSticky(entry.target)
        }
      }),
      { root: scrollport, threshold: 0.5 }
    );

    document.querySelectorAll('.jstree-leaf').forEach(leaf => observer.observe(leaf))
    addObservers()
    $("#toc").on("open_node.jstree", elements => addObservers())
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

  #scrollComponentToTop(componentElement) {
    const [scrollBox] = this.element.get()
    const [component] = componentElement.get()
    const firstComponent = scrollBox.querySelector('li')
    // Note: a larger scrollDistance means that the scrollport has scrolled
    // a greater distance from the initial position (i.e. the componentElement
    // will appear closer to the top of the screen)
    const scrollDistance = component.offsetTop - firstComponent.offsetTop - (this.#parentComponentLink(component)?.offsetHeight || 0)
    scrollBox.scrollTop = scrollDistance
  }

  #makeParentSticky(element) {
    this.#parentComponentLink(element)?.classList?.add('sticky-top')
  }

  #parentComponentLink(element) {
    return element
      .closest('ul')
      ?.closest('li')
      ?.querySelector('a')
  }
}
