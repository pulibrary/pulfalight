
<template>
  <div class="document-navigator-tree">
    <div v-for="siblingTree of this.tree.previousTrees">
      <document-navigator-tree :tree="siblingTree" :expanded="false" />
    </div>

    <div v-if="this.expanded">
      <div v-for="sibling of this.tree.previousSiblings()">
        <document-navigator-item :pulfa-document="sibling" />
      </div>
    </div>

    <document-navigator-item :pulfa-document="this.tree.root" />

    <div v-if="this.expanded">
      <div v-for="sibling of this.tree.nextSiblings()">
        <document-navigator-item :pulfa-document="sibling" />
      </div>
    </div>

    <div v-for="siblingTree of this.tree.nextTrees">
      <document-navigator-tree :tree="siblingTree" :expanded="false" />
    </div>

  </div>
</template>

<script>
/**


**/

export default {
  name: 'DocumentNavigator',
  components: {
    'document-navigator-tree', DocumentNavigatorTree,
    'document-navigator-item', DocumentNavigatorItem
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
  }
}

</script>
<style lang="scss" scoped>
</style>
