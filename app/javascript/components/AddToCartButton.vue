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
      required: true,
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
        subcontainers: this.subcontainers,
        unitid: this.unitid,
        physloc: this.physloc,
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
