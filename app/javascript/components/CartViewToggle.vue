<template>
  <div class="cart-wrapper">
    <input-button
      v-on:button-clicked="toggleCartView($event)"
      type="button"
      variation="text"
      hideLabel
    >
      <lux-icon-base width="30" height="30" icon-name="CartViewToggle" icon-color="#ffffff">
        <cart-icon></cart-icon>
      </lux-icon-base>
    </input-button>
    <span class="badge" id="count"> {{ items.length }} </span>
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
    }
  },
  methods: {
    toggleCartView(event) {
      this.$store.commit("TOGGLE_VISIBILITY")
    }
  }
}
</script>

<style lang="scss" scoped>
@import "lux-design-system/dist/system/tokens/tokens.scss";
#count {
  font-size: 12px;
  font-family: $font-family-text;
  background: #ff0000;
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
