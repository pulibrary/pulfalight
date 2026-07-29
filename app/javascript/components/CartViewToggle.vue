<template>
  <div class="cart-wrapper">
    <lux-input-button
      v-on:click="toggleCartView($event)"
      role="button"
      type="button"
      variation="text"
      hideLabel
    >
      <lux-icon-base width="30" height="30" icon-name="CartViewToggle" icon-color="#ffffff">
        <cart-icon></cart-icon>
      </lux-icon-base>
    </lux-input-button>
    <span class="badge" id="count">
      <span aria-hidden="true">{{ items.length }}</span>
      <span class="sr-only">{{ cartSummary }}</span>
    </span>
  </div>
</template>

<script>
import { mapState, mapGetters } from "vuex"
import LuxIconCart from './RequestCartIcon.vue'
export default {
  name: "CartViewToggle",
  components: {
    'cart-icon': LuxIconCart
  },
  computed: {
    items: {
      get() {
        return this.$store.state.cart.items
      }
    },
    cartSummary() {
      const count = this.items.length
      const suffix = count === 1 ? "" : "s"
      return `${count} item${suffix} in request cart`
    }
  },
  methods: {
    toggleCartView(event) {
      document.dispatchEvent(new Event('TOGGLE_CART'))
    }
  }
}
</script>

<style lang="scss" scoped>
@use "lux-design-system/dist/style.scss";
#count {
  font-size: 12px;
  font-family: style.$font-family-text;
  background: style.$color-red;
  color: #fff;
  padding: 0 5px;
  vertical-align: super;
  margin-left: -22px;
  margin-top: auto;
  margin-bottom: auto;
}
.badge {
  padding-left: 9px;
  padding-right: 9px;
  -webkit-border-radius: 9px;
  -moz-border-radius: 9px;
  border-radius: 9px;
}
.cart-wrapper {
  display: flex;
}
</style>
