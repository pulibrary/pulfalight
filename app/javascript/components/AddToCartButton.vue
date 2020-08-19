
<template>
  <div>
    <input-button @button-clicked="addToCart" variation="solid" size="small">
      <slot />
    </input-button>
  </div>
</template>

<script>
import store from "../store"
import { mapState, mapGetters } from "vuex"

export default {
  name: "AddToCartButton",
  props: {
    callnumber: {
      type: String,
      default: "",
      required: true,

    },

    referencenumber: {
      type: String,
      default: "",
      required: true,

    },

    title: {
      type: String,
      default: "",
      required: true,

    },

    containers: {
      type: Array,
      default: () => [],
      required: false,

    },

    subcontainers: {
      type: Array,
      default: () => [],
      required: false,
    },

    unitid: {
      type: Object,
      default: () => {},
      required: true,
    },

    physloc: {
      type: String,
      default: "",
      required: true,

    },

    location: {
      type: String,
      default: "",
      required: true,

    },

    subtitle: {
      type: String,
      default: "",
      required: false,

    },

    itemdate: {
      type: String,
      default: "",
      required: false,

    },

    itemnumber: {
      type: String,
      default: "",
      required: false,

    },

    itemvolume: {
      type: String,
      default: "",
      required: false,

    },

    accessnote: {
      type: String,
      default: "",
      required: false,

    },

    extent: {
      type: String,
              default: "",
              required: false,

    },

    itemurl: {
      type: String,
              default: "",
              required: false,

    }
  },
  methods: {
    addToCart() {
      store.dispatch("addItemToCart", this.item)
    }
  },
  computed: {
    item: function() {

    },
    items: {

    },
    ...mapState({
      cart: state => store.state.cart,
    })
  }

}

</script>

<style scoped></style>
