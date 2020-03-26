<template>
  <div v-bind:class="{ 'lux-navigator-item': true, selected: selected }">
    <div class="row">

      <div class="col-sm-1">
        <expand-children-button
          v-if="hasChildren"
          :expanded="expandedState"
          v-on:expand-children="updateExpanded" />
      </div>

      <div class="col-sm-1">
        <a>{{this.pulfaDocument.type}}</a>
      </div>

      <div class="col-sm-8">
        <div class="index_title document-title-heading my-w-75 w-md-100 order-0">
          <a :href="catalogUrl">{{this.pulfaDocument.title}}</a>
        </div>
      </div>

      <div v-if="hasOnlineContent" class="col-sm-2">
        <online-content-icon />
      </div>
    </div>

    <div class="row">
      <div class="col-auto">
        <div data-arclight-truncate="true" data-truncate-more="view more ▶" data-truncate-less="view less ▼">

          <div class="responsive-truncate">
            <p>{{this.pulfaDocument.abstract}}</p>
          </div>

        </div>
      </div>
    </div>

  </div>
</template>

<script>
import ExpandChildrenButton from './ExpandChildrenButton'
import OnlineContentIcon from './OnlineContentIcon'

export default {
  name: 'NavigatorItem',
  components: {
    'expand-children-button': ExpandChildrenButton,
    'online-content-icon': OnlineContentIcon
  },
  props: {
    pulfaDocument: {
      type: Object,
      default: null
    },
    hasChildren: {
      type: Boolean,
      default: false
    },
    expanded: {
      type: Boolean,
      default: false
    },
    selected : {
      type: Boolean,
      default: false
    }
  },
  data: function () {
    return {
      expandedState: this.expanded
    }
  },
  computed: {
    catalogUrl: function () {
      return `/catalog/${this.pulfaDocument.id}`
    },
    hasOnlineContent: function () {
      return this.pulfaDocument.hasOnlineContent
    }
  },
  methods: {
    updateExpanded: function (updatedState) {
      this.expandedState = updatedState
      // This is necessary for the parent component
      this.$emit('expand-children', this.expandedState)
    }
  }
}

</script>
<style lang="scss" scoped>
</style>
