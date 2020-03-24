<template>
  <ul class="document-navigator-tree">
    <ul v-if="!this.fetching">
      <li v-for="parent in parents">
        <document-navigator-item :pulfa-document="parent" />
      </li>
    </ul>

    <div v-if="!this.fetching">
      <document-navigator-item :pulfa-document="root" />

      <ul v-if="!this.fetching">
        <li v-for="child in children">
          <document-navigator-item :pulfa-document="parent" />
        </li>
      </ul>
    </div>

    <ul v-if="!this.fetching">
      <li v-for="child in children">
        <document-navigator-item :pulfa-document="child" />
      </li>
    </ul>
  </ul>
</template>

<script>
import DocumentNavigatorItem from './DocumentNavigatorItem'
import Navigator from '../document-navigator'

export default {
  name: 'DocumentNavigator',
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
      children: []
    }
  },
  computed: {
    root: function () {
      return this.tree.root
    },

    parentTrees: function () {
      // This might be best restructured in the low-level API
      return this.parents.map( parent => {
        const nav = new Navigator(parent)
        return nav.tree
      })
    }
  },
  methods: {
    fetchParents: function () {
      this.fetching = true
      const request = this.tree.root.parents()
      request.then( docs => {
        this.fetching = false
        this.parents = docs
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

  },
  mounted() {
    this.tree.build()
    this.fetchParents()
    this.fetchChildren()
  },
}

</script>
<style lang="scss" scoped>
</style>
