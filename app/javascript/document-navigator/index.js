
class PulfaDocument {
  constructor(solrDocument) {
    this.solrDocument = solrDocument
    if (!this.solrDocument) {
      console.error('Trying to build a Document from null')
    }

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

  mapSolrDocumentFields() {
    // This maps the Solr Document fields to properties
    this.id = this.solrDocument.id
    this.eadId = this.solrDocument['ead_ssi']
    this.titles = this.solrDocument['normalized_title_ssm']
    if (this.titles instanceof Array) {
      this.title = this.titles.shift()
    } else {
      this.title = this.titles
    }
    this.abstract = this.solrDocument['abstract_ssm']
    if (this.solrDocument['parent_ssm']) {
      this.parentIds = this.solrDocument['parent_ssm']
    }
    this.type = this.solrDocument['type']
  }

  previousTrees() {
    return []
  }

  nextTrees() {
    return []
  }

  get queryUrlBase() {

    return '/catalog.json';
  }

  get queryDocumentUrl() {

    return `${this.queryUrlBase}?q=id:`
  }

  buildDocumentQuery(id) {
    let queryId = id
    if (queryId != this.eadId) {
      queryId = `${this.eadId}${id}`
    }
    return `${this.queryDocumentUrl}${queryId}`
  }

  get queryChildDocumentUrl() {

    return `${this.queryUrlBase}?q=parent_ssm:`
  }

  buildChildDocumentQuery(id) {
    let queryId = id

    return `${this.queryChildDocumentUrl}${queryId}`
  }

  async buildChildren() {
    if (this._children.length > 0) {
      return
    }

    const childQueryUrl = this.buildChildDocumentQuery(this.id)
    const solrData = await fetch(childQueryUrl).then( response => response.json() ).then( solrDocument => solrDocument['data'] )
    this._children = PulfaDocument.buildPulfaDocuments(solrData)
  }

  async children() {
    await this.buildChildren()
    return this._children
  }

  async buildChildTrees() {
    if (this.fetchingTrees) {
      return
    }
    this.fetchingTrees = true

    this._childTrees = []
    const childQueryUrl = this.buildChildDocumentQuery(this.id)
    const solrData = await fetch(childQueryUrl).then( response => response.json() ).then( solrDocument => solrDocument['data'] )
    this._children = PulfaDocument.buildPulfaDocuments(solrData)
    this._childTrees = this._children.map( child => new DocumentTree(child) )

    this.fetchingTrees = false

    return this._childTrees
  }

  async childTrees() {
    await this.buildChildTrees()
    return this._childTrees
  }

  static buildPulfaDocuments(solrData) {
    return solrData.map( data => {
      const doc = { id: data.id }
      for (const key in data['attributes']) {
        const attributes = data['attributes'][key]
        const nestedAttributes = attributes['attributes']
        doc[key] = nestedAttributes['value']
      }

      let pulfaClass
      const types = data['type']
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

      const pulfaDoc = new pulfaClass(doc)
      return pulfaDoc
    })
  }

  static buildPulfaDocument(solrData) {
    const solrDocuments = PulfaDocument.buildPulfaDocuments(solrData)

    return solrDocuments.shift()
  }

  async buildParents() {
    if (this.fetching) {
      return
    }
    this.fetching = true

    this._parents = []
    const parentId = this.parentIds.pop()
    if (parentId) {
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

  async buildSiblings() {
    if (this.fetching) {
      return
    }

    this._previousSiblings = []
    this._nextSiblings = []

    const lastParent = this._parents[this._parents.length - 1]
    if (!lastParent) {
      return
    }
    this.fetching = true
    const children = await lastParent.children()

    for (const child of children) {
      const lastSibling = this._previousSiblings[this._previousSiblings.length - 1]
      if (lastSibling && lastSibling.id === this.id) {
        this._nextSiblings.push(child)
      } else {
        this._previousSiblings.push(child)
      }

      // Remove this node from the set of ordered, previous sibling nodes
      if (this._previousSiblings.length > 1) {
        this._previousSiblings.pop()
      }

      this._siblings = this._previousSiblings + this._nextSiblings
    }

    this.fetching = false
  }

  async siblings() {
    await this.buildSiblings()
    return this._siblings
  }

  async previousSiblings() {
    await this.buildSiblings()
    return this._previousSiblings
  }

  async nextSiblings() {
    await this.buildSiblings()
    return this._nextSiblings
  }
}

class PulfaCollection extends PulfaDocument {

  mapSolrDocumentFields() {
    // This maps the Solr Document fields to properties
    this.id = this.solrDocument.id
    this.eadId = this.solrDocument['ead_ssi']
    this.title = this.solrDocument['normalized_title_ssm']
    this.abstract = this.solrDocument['abstract_ssm']
    if (this.solrDocument['parent_ssm']) {
      this.parentIds = this.solrDocument['parent_ssm']
    }
    this.type = this.solrDocument['type']
  }
}

class PulfaSeries extends PulfaDocument {
  mapSolrDocumentFields() {
    // This maps the Solr Document fields to properties
    this.id = this.solrDocument.id
    this.eadId = this.solrDocument['ead_ssi']
    this.title = this.solrDocument['normalized_title_ssm']
    this.abstract = this.solrDocument['abstract_ssm']
    if (this.solrDocument['parent_ssm']) {
      const parentId = this.solrDocument['parent_ssm']
      this.parentIds = [parentId]
    }
    this.type = this.solrDocument['type']
  }
}

class DocumentTree {
  constructor(root, selectedChild) {
    this.root = root
    this.selectedChild = selectedChild

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

      const pulfaTree = new DocumentTree(pulfaDocument, this.root)
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
    this._childTrees = children.map( child => new DocumentTree(child, this.selectedChild) )

    this.fetchingTrees = false

    return this._childTrees
  }

  async childTrees() {
    await this.buildChildTrees()
    return this._childTrees
  }

  async build() {
    this.parents = await this.root.parents()
    this.parentTrees = await this.parentTrees()
    this.lastParentTree = this.parentTrees.pop()

    if (this.lastParentTree) {
      await this.lastParentTree.build()
      if (this.lastParentTree.lastParentTree) {
        this.lastParentTree = this.lastParentTree.lastParentTree
      }
    }

    // Siblings do not have parents
    //this.previousSiblings = await this.root.previousSiblings()
    //this.nextSiblings = await this.root.nextSiblings()

    // Children do not have siblings, nor parents
    //this.children = await this.root.children()
    this.childTrees = await this.childTrees()
  }
}

export default class DocumentNavigator {
  constructor(solrDocument) {
    if (solrDocument instanceof PulfaDocument) {
      this.document = solrDocument
    } else {
      this.document = new PulfaDocument(solrDocument)
    }

    this.tree = new DocumentTree(this.document)
  }

  async build() {
    await this.tree.build()
    return this
  }
}
