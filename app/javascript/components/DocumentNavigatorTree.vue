<template>
  <ul class="document-navigator-tree">
    <template v-if="fetching">
      <div class="al-hierarchy-placeholder">
        <h3 class="col-md-9"></h3>
        <p class="col-md-6"></p>
        <p class="col-md-12"></p>
        <p class="col-md-3"></p>
      </div>
    </template>

    <template v-else>
      <li>
        <document-navigator-item
          :pulfa-document="root"
          :selected="isSelected(root)"
          :has-children="childTrees.length > 0"
          :expanded="expandedState"
          v-on:expand-children="updateExpanded" />
      </li>
    </template>

    <ul v-if="!fetching && expandedState">
      <li v-for="childTree in childTrees">
        <document-navigator-tree :tree="childTree" :expanded="true" />
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
      childTrees: [],
      expandedState: this.expanded
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
    updateExpanded: function (updatedState) {
      this.expandedState = updatedState
    }
  },
  mounted: function () {
    this.childTrees = this.tree.childTrees
    console.log(this.tree.selectedChild)
  }
}

</script>
<style lang="scss" scoped>
  .selected {
    background-color: rgb(252, 248, 227);
  }
</style>
