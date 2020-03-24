<template>

    <ul class="document-navigator-tree">
      <div v-if="!this.fetching">
        <li v-for="parentTree in parentTrees">
          <document-navigator-tree :tree="parentTree" />
        </li>
      </div>

      <li v-if="!this.fetching">
        <div class="row">
          <div class="col-auto">
            <a class="al-toggle-view-children " aria-label="View" href="#">
              <span class="blacklight-icons">+</span>
            </a>
          </div>

          <div class="col-auto">
            <document-navigator-item :pulfa-document="root" />
          </div>
        </div>
      </li>

      <ul v-if="!this.fetching && expanded">
        <li v-for="childTree in childTrees">
          <document-navigator-tree :tree="childTree" />
        </li>
      </ul>

    </ul>
</template>

<script>
import DocumentNavigatorItem from './DocumentNavigatorItem'
import Navigator from '../document-navigator'

export default {
  name: 'DocumentNavigatorTree',
  components: {
    'document-navigator-item': DocumentNavigatorItem
  },
  props: {
    tree: {
      type: Object,
      default: null
    },
    expanded: {
      type: Boolean,
      default: false
    }
  },
  data: function() {
    return {
      fetching: false,
      parents: [],
      parentTrees: [],
      children: [],
      childTrees: []
    }
  },
  computed: {
    root: function () {
      return this.tree.root
    }
  },
  methods: {
    fetchParents: function () {
      this.fetching = true
      const request = this.tree.root.parents()

      request.then( docs => {
        this.fetching = false

        // Only use the most recent parent
        const lastParent = docs.pop()
        this.parents = [lastParent]
      }).catch( error => {
        this.fetching = false
        console.error(`Failed to request the collection: ${error.message}`)
      })
    },

    fetchParentTrees: function () {
      this.fetching = true
      const request = this.tree.root.parentTrees()

      request.then( docs => {
        console.log(this.tree)
        console.log(docs)
        this.fetching = false

        const lastParent = docs.pop()
        if (lastParent) {
          this.parentTrees = [lastParent]
        }
      }).catch( error => {
        this.fetching = false
        console.error(`Failed to request the collection: ${error.message}`)
      })
    },

    fetchChildren: function () {
      this.fetching = true
      const request = this.tree.root.children()
      request.then( docs => {
        this.fetching = false
        this.children = docs
      }).catch( error => {
        this.fetching = false
        console.error(`Failed to request the collection: ${error.message}`)
      })
    },

    fetchChildTrees: function () {
      this.fetching = true

      const request = this.tree.root.childTrees()
      request.then( docs => {
        this.fetching = false
        this.childTrees = docs
      }).catch( error => {
        this.fetching = false
        console.error(`Failed to request the collection: ${error.message}`)
      })
    },

  },
  mounted() {
    this.tree.build()
    //this.fetchParents()
    this.fetchParentTrees()
    //this.fetchChildren()
    this.fetchChildTrees()
  },
}

</script>
<style lang="scss" scoped>
</style>
