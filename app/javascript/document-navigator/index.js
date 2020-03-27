
class PulfaDocumentFinder {
  constructor(tree) {
    this.tree = tree
  }

  getCollection() {
    return PulfaDocument.buildPulfaDocument(this.tree.root, this)
  }

  findDocument(id) {
    return PulfaDocument.buildPulfaDocument(this.tree[id], this)
  }

  findParents(id) {
    if (!this.tree[id].hasOwnProperty('parents')) {
      return []
    }

    return PulfaDocument.buildPulfaDocuments(this.tree[id]['parents'], this)
  }

  findChildren(id) {
    if (!this.tree[id].hasOwnProperty('children')) {
      return []
    }

    return PulfaDocument.buildPulfaDocuments(this.tree[id]['children'], this)
  }
}

class PulfaDocumentSolrFinder extends PulfaDocumentFinder {

  constructor() {
    this.fetching = false
  }

  get queryUrlBase() {
    return '/catalog.json';
  }

  get queryDocumentUrl() {
    return `${this.queryUrlBase}?q=id:`
  }

  buildDocumentQuery(id) {
    let queryId = id
    return `${this.queryDocumentUrl}${queryId}`
  }

  get queryChildDocumentUrl() {
    return `${this.queryUrlBase}?per_page=1000000&q=tree_parent_ssim:`
  }

  buildChildDocumentQuery(id) {
    let queryId = id
    return `${this.queryChildDocumentUrl}${queryId}`
  }

  async buildChildren() {
    if (this.fetching) {
      return
    }
    this.fetching = true
    this._children = []

    const childQueryUrl = this.buildChildDocumentQuery(this.id)
    const solrData = await fetch(childQueryUrl).then( response => response.json() ).then( solrDocument => solrDocument['data'] )
    this.fetching = false
    this._children = PulfaDocument.buildPulfaDocuments(solrData)
  }

  async children() {
    await this.buildChildren()
    return this._children
  }

  async buildParents() {
    if (this.fetching) {
      return
    }
    this.fetching = true

    this._parents = []

    //const parentId = this.parentIds.pop()
    //if (parentId) {
    for (const parentId of this.parentIds) {
      const queryUrl = this.buildDocumentQuery(parentId)

      const solrData = await fetch(queryUrl).then( response => response.json() ).then( solrDocument => solrDocument['data'] )
      const pulfaDocument = PulfaDocument.buildPulfaDocument(solrData)
      this._parents.push(pulfaDocument)
    }

    this.fetching = false

    return this._parents
  }

  async parents() {
    await this.buildParents()
    return this._parents
  }
}

class PulfaDocument {
  static buildPulfaDocuments(solrData, finder) {

    return solrData.map( data => {
      const doc = data

      let pulfaClass
      const types = data['level_ssm']
      const type = types.shift()
      switch (type) {
        case 'collection':
          pulfaClass = PulfaCollection
          break
        case 'Series':
          pulfaClass = PulfaSeries
          break
        default:
          pulfaClass = PulfaDocument
      }

      // For these cases, the finder isn't needed
      const pulfaDoc = new pulfaClass(doc, finder)
      return pulfaDoc
    })
  }

  static buildPulfaDocument(solrData, finder) {
    const solrDocuments = PulfaDocument.buildPulfaDocuments(solrData)

    return solrDocuments.shift()
  }
  constructor(solrDocument, finder) {
    this.solrDocument = solrDocument
    if (!this.solrDocument) {
      console.error('Trying to build a Document from null')
    }
    this.finder = finder

    this.parentIds = []

    this.mapSolrDocumentFields()

    this._children = []
    this._parents = []
    this._parentTrees = []
    this._previousSiblings = []
    this._nextSiblings = []
    this._siblings = []
    this.fetching = false
    this.fetchingTrees = false
  }

  mapSolrTitles() {
    this.titles = this.solrDocument['normalized_title_ssm']
    if (this.titles instanceof Array) {
      this.title = this.titles.shift()
    } else {
      this.title = this.titles
    }
  }

  mapSolrParents() {
    if (this.solrDocument['parent_ssm']) {
      if (this.solrDocument['parent_ssm'] instanceof Array) {
        this.parentIds = this.solrDocument['parent_ssm']
      } else {
        this.parentIds = this.solrDocument['parent_ssm'].split(" and ")
      }
    }
  }

  mapSolrDocumentFields() {
    const ids = this.solrDocument.id
    this.id = ids.shift()
    this.eadId = this.solrDocument['ead_ssi']
    this.mapSolrTitles()
    this.abstracts = this.solrDocument['abstract_ssm']
    if (this.abstracts) {
      this.abstract = this.abstracts.shift()
    }
    this.mapSolrParents()
    this.type = this.solrDocument['type']
    let onlineContentValues = false
    if (this.solrDocument['has_online_content_ssim']) {
      onlineContentValues = this.solrDocument['has_online_content_ssim'].map( v => v == 'true' )
      this.hasOnlineContent = onlineContentValues.shift()
    }
  }

  async children() {
    this._children = await this.finder.findChildren(this.id)
    return this._children
  }

  async parents() {
    this._parents = await this.finder.findParents(this.id)
    return this._parents
  }
}

class PulfaCollection extends PulfaDocument {
  mapSolrParents() {
    if (this.solrDocument['parent_ssm']) {
      if (this.solrDocument['parent_ssm'] instanceof Array) {
        this.parentIds = this.solrDocument['parent_ssm']
      } else {
        // This is deprecated by the Solr Caching approach
        this.parentIds = this.solrDocument['parent_ssm'].split(" and ")
      }
    }
  }
}

class PulfaSeries extends PulfaDocument {
  mapSolrParents() {
    if (this.solrDocument['parent_ssm']) {
      if (this.solrDocument['parent_ssm'] instanceof Array) {
        this.parentIds = this.solrDocument['parent_ssm']
      } else {
        // This is deprecated by the Solr Caching approach
        this.parentIds = this.solrDocument['parent_ssm'].split(" and ")
      }
    }
  }
}

class DocumentTree {
  constructor(root, selectedChild) {
    this.root = root
    this.selectedChild = selectedChild ? selectedChild : this.root

    this.built = false

    this.parents = []
    this.fetchingTrees = false
    this._parentTrees = []
    this.children = []
    this._childTrees = []

    this.previousTrees = []
    this.nextTrees = []

    this.previousSiblings = []
    this.nextSiblings = []
  }

  async buildParentTrees() {
    if (this.fetchingTrees) {
      return
    }
    this.fetchingTrees = true

    this._parentTrees = []

    const pulfaDocuments = await this.root.parents()
    const pulfaDocument = pulfaDocuments.pop()
    if (pulfaDocument) {
      const pulfaTree = new DocumentTree(pulfaDocument, this.selectedChild)
      this._parentTrees.push(pulfaTree)
    }

    this.fetchingTrees = false

    return this._parentTrees
  }

  async parentTrees() {
    await this.buildParentTrees()
    return this._parentTrees
  }

  async buildChildTrees() {
    if (this.fetchingTrees) {
      return
    }
    this.fetchingTrees = true
    this._childTrees = []

    const children = await this.root.children()
    this._childTrees = children.map( child => new ChildDocumentTree(child, this.selectedChild) )

    this.fetchingTrees = false

    return this._childTrees
  }

  async childTrees() {
    await this.buildChildTrees()
    return this._childTrees
  }

  async build() {
    if (this.built) {
      return
    }

    this.parents = await this.root.parents()
    this.parentTrees = await this.parentTrees()
    this.lastParentTree = this.parentTrees.pop()

    if (this.lastParentTree) {
      await this.lastParentTree.build()
      if (this.lastParentTree.lastParentTree) {
        this.lastParentTree = this.lastParentTree.lastParentTree
      }
    }

    this.childTrees = await this.childTrees()
    for (const childTree of this.childTrees) {
      await childTree.build()
    }

    this.built = true
  }
}

class ChildDocumentTree extends DocumentTree {
  async build() {
    if (this.built) {
      return
    }

    this.childTrees = await this.childTrees()
    // This is disabled to prevent unnecessary recursion
    for (const childTree of this.childTrees) {
      //await childTree.build()
    }

    this.built = true
  }
}

export default class DocumentNavigator {
  constructor(solrDocument, navigationTree) {
    if (solrDocument instanceof PulfaDocument) {
      this.document = solrDocument
    } else {
      const finder = new PulfaDocumentFinder(navigationTree)
      this.document = new PulfaDocument(solrDocument, finder)
    }

    this.tree = new DocumentTree(this.document)
  }

  async build() {
    await this.tree.build()
    return this
  }
}
