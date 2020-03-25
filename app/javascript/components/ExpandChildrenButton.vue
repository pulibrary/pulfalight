<template>
  <div class="al-toggle-children-container">
    <button class="al-toggle-view-children collapsed" aria-label="View" v-on:click="toggle">
      <span class="blacklight-icons">
        <template v-if="expandedState">
          <svg width="24" height="24" viewBox="0 0 24 24" role="image" aria-labelled-by="bl-icon-minus-f3beb333aaffcc4e">
            <path d="M19 13H5v-2h14v2z" />
            <path d="M0 0h24v24H0z" fill="none" />
            <title id="bl-icon-minus-f3beb333aaffcc4e">minus icon</title>
          </svg>
        </template>
        <template v-else>
          <svg width="24" height="24" viewBox="0 0 24 24" role="image" aria-labelled-by="bl-icon-plus-f3beb333aaffcc4e">
            <path d="M19 13h-6v6h-2v-6H5v-2h6V5h2v6h6v2z"></path>
            <path d="M0 0h24v24H0z" fill="none"></path>
            <title id="bl-icon-plus-f3beb333aaffcc4e">plus icon</title>
          </svg>
        </template>
      </span>
    </button>
  </div>
</template>
<script>

export default {
  name: 'ExpandChildrenButton',
  props: {
    expanded: {
      type: Boolean,
      default: false
    }
  },
  data: function () {
    return {
      expandedState: this.expanded
    }
  },
  methods: {
    toggle: function () {
      this.expandedState = !this.expandedState
      this.$emit('expand-children', this.expandedState)
    }
  }
}

</script>
<style lang="scss" scoped>
</style>
