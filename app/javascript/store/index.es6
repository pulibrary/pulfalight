import { createStore } from 'vuex'
import { cartModule } from "./modules.es6"
import VuexPersist from "vuex-persist"

const vuexPersist = new VuexPersist({
  key: "lux",
  storage: window.localStorage
})

export const store = createStore({
  modules: {
    cart: cartModule
  },
  plugins: [vuexPersist.plugin]
})
