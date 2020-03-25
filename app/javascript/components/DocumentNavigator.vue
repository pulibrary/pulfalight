<template>

  <div v-if="!fetching && tree" class="document-navigator">
    <document-navigator-tree :tree="tree" :expanded="true" />
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
    document: {
      type: Object,
      default: null
    }
  },
  data: function () {
    return {
      tree: null,
      fetching: false
    }
  },
  computed: {
    navigator() {
      return new Navigator(this.document)
    }
  },
  mounted() {
    this.fetching = true
    const request = this.navigator.build()

    request.then(built => {
      this.fetching = false

      if (built.tree.lastParentTree) {
        this.tree = built.tree.lastParentTree
      } else {
        this.tree = built.tree
      }
    })
  }
}

</script>
<style lang="scss" scoped>
</style>
