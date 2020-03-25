<template>
  <div v-bind:class="{ 'lux-navigator-item': true, selected: selected }">
    <div class="row">

      <div class="col-sm-1">
        <expand-children-button />
      </div>

      <div class="col-sm-1">
        <a>{{this.pulfaDocument.type}}</a>
      </div>

      <div class="col-sm-8">
        <div class="index_title document-title-heading my-w-75 w-md-100 order-0">
          <a :href="catalogUrl">{{this.pulfaDocument.title}}</a>
        </div>
      </div>

      <div class="col-sm-2">
        <div class="my-w-25 w-md-100 order-12 order-md-1">
          <div class="d-flex justify-content-end">
            <online-content-icon />
          </div>
        </div>
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
    selected : {
      type: Boolean,
      default: false
    }
  },
  computed: {
    catalogUrl: function () {
      return `/catalog/${this.pulfaDocument.id}`
    }
  }
}

</script>
<style lang="scss" scoped>
</style>
