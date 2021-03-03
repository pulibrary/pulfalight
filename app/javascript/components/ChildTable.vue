<template>
  <div class="child-component-table">
    <pulfa-data-table
      width="100%"
      :caption="caption"
      :columns="columns"
      :json-data="components"/>
  </div>
</template>

<script>
import system from 'lux-design-system'
import PulfaDataTable from './PulfaDataTable.vue'
export default {
  name: "ChildTable",
  components: {
    'pulfa-data-table': PulfaDataTable
  },
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
