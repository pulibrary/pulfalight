<template>
  <div v-if="tree">
    <template v-if="fetching">
      <div class="al-hierarchy-placeholder">
        <h3 class="col-md-9"></h3>
        <p class="col-md-6"></p>
        <p class="col-md-12"></p>
        <p class="col-md-3"></p>
      </div>
    </template>
    <template v-else>
      <div class="document-navigator">
        <document-navigator-tree :tree="tree" :expanded="true" />
      </div>
    </template>
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
    navigationTree: {
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
      return new Navigator(this.navigationTree.root, this.navigationTree)
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
