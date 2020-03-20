<template>
  <div class="document-navigator">
    <document-navigator-tree :tree="this.navigator.tree" :expanded="true" />
  </div>
</template>

<script>
import DocumentNavigatorTree from './DocumentNavigatorTree'
import Navigator from '../document-navigator'

export default {
  name: 'DocumentNavigator',
  components: {
    'document-navigator-tree': DocumentNavigatorTree
  },
  props: {
    root: {
      type: Object,
      default: null
    }
  },
  computed: {
    navigator () {
      const solrDocument = this.root
      return new Navigator(solrDocument)
    }
  }
}

</script>
<style lang="scss" scoped>
</style>
