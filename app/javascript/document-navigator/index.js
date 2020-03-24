
class PulfaDocument {
  constructor(solrDocument) {
    this.solrDocument = solrDocument

    this.mapSolrDocumentFields()

    this._children = []
    this._parents = []
    this._previousSiblings = []
    this._nextSiblings = []
    this._siblings = []
  }

  mapSolrDocumentFields() {
    // This maps the Solr Document fields to properties
    console.log(this.solrDocument)

    this.id = this.solrDocument.id
    this.eadId = this.solrDocument['ead_ssi']
    this.titles = this.solrDocument['normalized_title_ssm']
    this.title = this.titles.shift()
    this.abstract = this.solrDocument['abstract_ssm']
    this.parentIds = this.solrDocument['parent_ssm']
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
    if (queryId != this.eadId) {
      queryId = `${this.eadId}${id}`
    }

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
    if (this._parents.length > 0) {
      return
    }

    for (const parentId of this.parentIds) {
      const queryUrl = this.buildDocumentQuery(parentId)

      const solrData = await fetch(queryUrl).then( response => response.json() ).then( solrDocument => solrDocument['data'] )
      const pulfaDocument = PulfaDocument.buildPulfaDocument(solrData)
      this._parents.push(pulfaDocument)
    }

    return this._parents
  }

  async parents() {
    await this.buildParents()
    return this._parents
  }

  async buildSiblings() {
    if (this.siblings.length > 0) {
      return
    }

    const lastParent = this._parents[this._parents.length - 1]
    const children = await lastParent.children()

    for (const child of children) {
      const lastSibling = this._previousSibling[this._previousSibling.length - 1]
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
    this.parentIds = this.solrDocument['parent_ssm']
  }
}

class PulfaSeries extends PulfaDocument {

  mapSolrDocumentFields() {
    // This maps the Solr Document fields to properties
    this.id = this.solrDocument.id
    this.eadId = this.solrDocument['ead_ssi']
    this.title = this.solrDocument['normalized_title_ssm']
    this.abstract = this.solrDocument['abstract_ssm']
    this.parentIds = this.solrDocument['parent_ssm']
  }
}

class DocumentTree {
  constructor(root) {
    this.root = root

    this.parents = []

    this.parentTrees = []
    this.previousTrees = []
    this.nextTrees = []

    this.previousSiblings = []
    this.nextSiblings = []
  }

  async build() {
    this.parents = await this.root.parents()
    console.log(this.root._parents)
    console.log(this.parents)
    this.previousSiblings = await this.root.previousSiblings()
    this.nextSiblings = await this.root.nextSiblings()
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
  }
}
