<template>
  <input-button type="button" variation="text" v-on:button-clicked="addToCart">
    <slot />
  </input-button>
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
    formParams: {
      type: Object,
      default: () => { {} },
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
        formParams: this.formParams
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
