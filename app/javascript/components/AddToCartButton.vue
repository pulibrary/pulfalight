<template>
  <lux-input-button role="button" type="button" variation="text" v-on:click="addToCart">
    <slot />
  </lux-input-button>
</template>

<script>
import { mapState, mapGetters } from "vuex"
export default {
  name: "AddToCartButton",
  props: {
    callnumber: {
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
      type: String,
      default: "",
      required: false,
    },
    location: {
      type: Object,
      default: () => { {} },
      required: false,
    },
    formParams: {
      type: Object,
      default: () => { {} },
      required: false,
    },
    restricted: {
      type: Boolean,
      default: false,
      required: false,
    }
  },
  methods: {
    addToCart() {
      this.$store.dispatch("addItemToCart", this.item)
    }
  },
  computed: {
    item: function() {
      return {
        callnumber: this.callnumber,
        title: this.title,
        containers: this.containers,
        location: this.location,
        formParams: this.formParams,
        restricted: this.restricted
      }
    },
    items: {
      get() {
        return this.cart.items
      }
    },
    ...mapState({
      cart: state => this.$store.state.cart,
    })
  }
}
</script>
