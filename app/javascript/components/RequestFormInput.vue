<template>
  <div>
    <input :id="inputID" :name="inputName" type="hidden" :value="inputValue"></input>
  </div>
</template>

<script>
export default {
  name: "RequestField",
  props: {
    name: {
      type: String,
      required: true
    },
    values: {
      type: Array,
      required: true,
      default: () => { [] }
    }
  },
  computed: {
    inputID: function () {
      return `${this.name}`
    },
    inputName: function () {
      return `${this.name}`
    },
    inputValue: function () {
      return this.values.join(',')
    }
  }
}
</script>
