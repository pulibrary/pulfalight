
<template>
  <div>
    <input :id="inputID(index)" :name="inputName" type="hidden" :value="inputValue(values)"></input>
  </div>
</template>

<script>
  // <input v-for="(value, index) in values" :key="index" :id="inputID(index)" :name="inputName" type="hidden" :value="inputValue(value)"></input>

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
    inputName: function () {
      return `${this.name}`
    },
  },
  methods: {
    inputID: function (index) {
      // return `${this.name}-${index}`
      return `${this.name}`
    },
    inputValue: function (value) {
      // ReferenceNumber_32101106190174: MC232_c002,MC232_c003
      // ReferenceNumber_32101106190174: MC232_c016,MC232_c015,MC232_c017
      //ItemInfo3_32101106190174:  1, 2
      //ItemInfo3_32101106190174:  15, 14, 16
      let output = value

      if (this.name.includes('ReferenceNumber')) {

      } else if(this.name.includes('ItemInfo3')) {

      }

      return output.join(',')
    }
  }
}

</script>
