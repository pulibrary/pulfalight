<template>
  <div class="child-component-table">
    <data-table
      :caption="caption"
      :columns="columns"
      :json-data="components"/>
  </div>
</template>

<script>
import system from 'lux-design-system'
export default {
  name: "ChildTable",
  props: {
    components: {
      type: Array,
      default: [],
      required: true,
    },
    parentTitle: {
      type: String,
      default: "",
      required: true
    }
  },
  data () {
    return {
      "columns": [
        { 'name': 'id', 'display_name': 'Select Items', 'align': 'center', 'checkbox': true },
        { 'name': 'title', 'display_name': 'Title', 'align': 'center', 'sortable': true },
        { 'name': 'date', 'sortable': true },
        { 'name': 'container', 'display_name': 'Container', 'sortable': true }
      ]
    }
  },
  computed: {
    caption() {
      return `${this.parentTitle} Content List`
    }
  }
}
</script>

<style lang="scss">
  .child-component-table caption {
    caption-side: top;
  }
</style>
