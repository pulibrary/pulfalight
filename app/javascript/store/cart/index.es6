export const cartState = {
  items: [],
  isVisible: false
}

export const cartActions = {
  addItemToCart(context, newItem) {
    const duplicate = context.state.items.find(item => item.callnumber === newItem.callnumber)
    if (typeof duplicate === "undefined") {
      context.commit("PUSH_ITEM_TO_CART", newItem)
    }

    if(context.state.isVisible === false)
      context.commit("TOGGLE_VISIBILITY")
  },
  removeItemFromCart(context, item) {
    context.commit("REMOVE_ITEM_FROM_CART", item)
    if(context.state.isVisible === true && context.state.items.length === 0)
      context.commit("TOGGLE_VISIBILITY")
  }
}

export const cartMutations = {
  TOGGLE_VISIBILITY(state) {
    state.isVisible = !state.isVisible
  },

  SET_CART(state, items) {
    state.items = items
  },

  PUSH_ITEM_TO_CART(state, item) {
    state.items.push(item)
  },

  REMOVE_ITEM_FROM_CART(state, payload) {
    const i = state.items.map(item => item.callnumber).indexOf(payload.callnumber)
    state.items.splice(i, 1)
    if (state.items.length == 0) {
      window.localStorage.clear()
    }
  }
}
