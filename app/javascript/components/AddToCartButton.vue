<template>
  <div>
    <button @click="addToCart">
      <slot />
    </button>
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
      required: false,
    },
    title: {
      type: String,
      default: "",
      required: true,
    },
    containers: {
      type: Array,
      default: "",
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
      required: false,
    },
    physloc: {
      type: String,
      default: "",
      required: false,
    },
    location: {
      type: String,
      default: "",
      required: false,
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
    },
    formParams: {
      type: Array,
      default: () => { [] },
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
      return {
        callnumber: this.callnumber,
        title: this.title,
        containers: this.containers,
        formParams: this.formParams
      }
    },
    items: {
      get() {
        return this.cart.items
      }
    },
    ...mapState({
      cart: state => store.state.cart,
    })
  }
}
</script>
