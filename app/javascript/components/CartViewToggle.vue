<template>
  <div>
    <input-button
      v-on:button-clicked="toggleCartView($event)"
      type="button"
      variation="text"
      hideLabel
    >
      <lux-icon-base width="30" height="30" icon-name="Cart" icon-color="#ffffff">
        <cart-icon></cart-icon>
      </lux-icon-base>
    </input-button>
    <span class="badge" id="count"> {{ cart.items.length }} </span>
  </div>
</template>

<script>
import store from "../store"
import { mapState, mapGetters } from "vuex"
import RequestCartIcon from './RequestCartIcon.vue'
export default {
  name: "CartViewToggle",
  components: {
    'cart-icon': RequestCartIcon
  },
  computed: {
    items: {
      get() {
        return this.cart.items
      }
    },
    ...mapState({
      cart: state => store.state.cart,
    })
  },
  methods: {
    toggleCartView(event) {
      store.commit("TOGGLE_VISIBILITY")
    }
  }
}
</script>

<style lang="scss" scoped>
$font-family-text: "franklin-gothic-urw", Helvetica, Arial, sans-serif;
#count {
  font-size: 12px;
  font-family: $font-family-text;
  background: #ff0000;
  color: #fff;
  padding: 0 5px;
  vertical-align: super;
  margin-left: -22px;
}
.badge {
  padding-left: 9px;
  padding-right: 9px;
  -webkit-border-radius: 9px;
  -moz-border-radius: 9px;
  border-radius: 9px;
}
</style>
