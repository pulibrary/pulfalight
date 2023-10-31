import Vue from 'vue/dist/vue.esm'
import Vuex from "vuex"

import { cartModule } from "./modules.es6"
import VuexPersist from "vuex-persist"

Vue.use(Vuex)

const vuexPersist = new VuexPersist({
  key: "lux",
  storage: window.localStorage,
})

export default new Vuex.Store({
  modules: {
    cart: cartModule
  },
  plugins: [vuexPersist.plugin],
})
