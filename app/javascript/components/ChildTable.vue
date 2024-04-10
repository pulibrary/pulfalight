<template>
  <div class="child-component-table">
    <pulfa-data-table
      width="100%"
      v-if="loaded"
      :caption="caption"
      :columns="columns"
      :loading="loading"
      :json-data="loaded_components"/>

      <table v-else border="1px" :class="['lux-data-table']">
        <caption>
          {{
          caption
          }}
        </caption>
        <thead>
          <tr><th class="loader">
              Loading..
            </th></tr>
        </thead>
      </table>
  </div>
</template>

<script>
import PulfaDataTable from './PulfaDataTable.vue'
export default {
  name: "ChildTable",
  components: {
    'pulfa-data-table': PulfaDataTable
  },
  props: {
    components: {
      type: Array,
      default: () => [],
      required: false,
    },
    component_id: {
      type: String,
      default: "",
      required: false
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
      ],
      "loaded_components": [],
      "loading": true
    }
  },
  mounted() {
    this.fetchComponents()
  },
  methods: {
    async fetchComponents() {
      if(this.component_id === "") {
        this.loaded_components = this.components
        this.loading = false
        return false
      }
      const response = await fetch(`/toc/${this.component_id}/child_table`)
      this.loaded_components = await response.json()
      this.loading = false
    }
  },
  computed: {
    caption() {
      return `${this.parentTitle} Content List`
    },
    loaded() {
      return this.loading === false
    }
  }
}
</script>

<style lang="scss">
.child-component-table {
  overflow: scroll;
  caption {
    caption-side: top;
  }
  table {
    width: 100%;
    th.loader {
      text-align: center;
    }
}
}
</style>
