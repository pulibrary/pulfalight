<template>
  <div class="document-navigator-tree">
    <div v-for="siblingTree of this.tree.previousTrees">
      <document-navigator-tree :tree="siblingTree" :expanded="false" />
    </div>

    <div v-if="this.expanded">
      <div v-for="sibling of this.tree.previousSiblings">
        <document-navigator-item :pulfa-document="sibling" />
      </div>
    </div>

    <document-navigator-item :pulfa-document="tree.root" />

    <div v-if="this.expanded">
      <div v-for="sibling of tree.nextSiblings">
        <document-navigator-item :pulfa-document="sibling" />
      </div>
    </div>

    <div v-for="siblingTree of this.tree.nextTrees">
      <document-navigator-tree :tree="siblingTree" :expanded="false" />
    </div>

  </div>
</template>

<script>
import DocumentNavigatorItem from './DocumentNavigatorItem'

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
  mounted() {
    this.tree.build()
  }
}

</script>
<style lang="scss" scoped>
</style>
