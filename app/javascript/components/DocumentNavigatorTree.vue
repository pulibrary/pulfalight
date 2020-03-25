<template>
    <ul class="document-navigator-tree">

      <li v-if="!this.fetching">
        <document-navigator-item :pulfa-document="root" :selected="isSelected(root)"/>
      </li>

      <ul v-if="!this.fetching">
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
    selected: {
      type: Boolean,
      default: false
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
    isSelected: function(pulfaDocument) {
      if (this.tree.selectedChild) {
        return pulfaDocument.id == this.tree.selectedChild.id
      }

      return false
    },

  },
  mounted: function () {
    this.childTrees = this.tree.childTrees
  }
}

</script>
<style lang="scss" scoped>
  .selected {
    background-color: rgb(252, 248, 227);
  }
</style>
