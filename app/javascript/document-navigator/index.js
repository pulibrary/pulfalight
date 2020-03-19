
class PulfaDocument {
  constructor(solrDocument) {
    this.solrDocument = solrDocument
    this.parentIds = solrDocument.parent_ids

    this.mapSolrDocumentFields()

    /*
    this.children = []
    this.buildChildren()

    this.parents = []
    this.buildParents()

    this.previousSiblings = []
    this.nextSiblings = []
    this.buildSiblings()
    */
  }

  mapSolrDocumentFields() {
    // This maps the Solr Document fields to properties
    this.id = this.solrDocument.id
    this.title = this.solrDocument['title_ssm']
    this.abstract = this.solrDocument['abstract_ssm']
    this.parentIds = this.solrDocument['parent_ssm']
  }

  get queryUrlBase() {

    return '/catalog.json';
  }

  get queryDocumentUrl() {

    return `${this.queryUrlBase}?q=id:`
  }

  buildDocumentQuery(id) {

    return `${this.queryDocumentUrl}${id}`
  }

  get queryChildDocumentUrl() {

    return `${this.queryUrlBase}?q=parent_ssm:`
  }

  buildChildDocumentQuery(id) {

    return `${this.queryChildDocumentUrl}${id}`
  }

  async buildChildren() {
    const childQueryUrl = this.buildChildDocumentQuery(this.id)
    const childDocuments = await fetch(childQueryUrl).foo()

    for (childDocument of childDocuments) {

      const childDocument = await fetch(queryUrl).then( response => response.json() ).then( solrDocument => new PulfaDocument(solrDocument) )
      this.children.push(childDocument)
    }
  }

  get children() {
    await this.buildChildren()
    return this.children
  }

  async buildParents() {
    for (parentId of this.parentIds) {
      const queryUrl = this.buildDocumentQuery(parentId)

      const parentDocument = await fetch(queryUrl).then( response => response.json() ).then( solrDocument => new PulfaDocument(solrDocument) )
      this.parents.push(parentDocument)
    }
  }

  get parents() {
    await this.buildParents()
    return this.parents
  }

  /**
   *
   */
  async buildSiblings() {
    const lastParent = this.parents[-1]
    const children = lastParent.children

    for (child of children) {
      if (this.previousSiblings[-1] && this.previousSiblings[-1].id === this.id) {
        this.nextSiblings.push(child)
      } else {
        this.previousSiblings.push(child)
      }

      // Remove this node from the set of ordered, previous sibling nodes
      if (this.previousSiblings.length > 1) {
        this.previousSiblings.pop()
      }
    }
  }

  get children() {
    await this.buildChildren()
    return this.children
  }

}

class DocumentTree {
  construction(root) {
    this.root = root
    this.parents = []
    this.parentTrees = []

    this.build()
  }

  build() {
    this.parents = this.roots.parents
    for (parent of this.parents) {
      const parentTree = new DocumentTree(parent)
      this.parentTrees.push(parentTree)
    }
  }
}

export default class DocumentNavigator {
  constructor(solrDocument) {
    this.document = new PulfaDocument(solrDocument)
    this.tree = new DocumentTree(this.document)
  }
}
