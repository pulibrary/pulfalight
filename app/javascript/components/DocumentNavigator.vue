
<template>
  <div class="document-navigator">

    <document-navigator-tree :tree="this.tree" />

  </div>
</template>

<script>
/**


**/

export default {
  name: 'DocumentNavigator',
  components: {
    'document-navigator-tree', DocumentNavigatorTree
  },
  props: {
    root: {
      type: Object,
      default: null
    }
  },
  computed: {
    tree () {
      const solrDocument = this.root
      return new Navigator(solrDocument)
    }
  }
}

</script>
<style lang="scss" scoped>
</style>
