import { cartState, cartMutations, cartActions } from "./cart/index"

export const cartModule = {
  state: cartState,
  actions: cartActions,
  mutations: cartMutations
}

let modules
export default modules = { cartModule }
