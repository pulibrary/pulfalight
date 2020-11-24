// import Vuex from "vuex"
// import { createLocalVue, mount } from "@vue/test-utils"
// import RequestCart from "components/RequestCart"
//
// // use vuex state
// const localVue = createLocalVue()
// localVue.use(Vuex)
//
// let wrapper
// let store
//
// describe("LoginForm.vue", () => {
//   beforeEach(() => {
//     store = new Vuex.Store({
//       state: {
//         cart: {
//           items: [ {
//             title: "My word"
//           } ]
//         }
//       }
//     })
//
//   })
//
//   it("is visible", () => {
//     debugger;
//     wrapper = mount(RequestCart, {
//       computed: {
//         isVisible: () => true
//       },
//       // mocks: {
//       //   $store: {
//       //     state: {
//       //       cart: {
//       //         items: [ { title: "My word" } ],
//       //         // isVisible: { get() { return true } }
//       //       }
//       //     }
//       //   }
//       // },
//       localVue,
//       store,
//       propsData: {
//         configuration: {},
//       },
//     })
//
//     wrapper.overview()
//     console.log(wrapper.vm.$store.state)
//     // expect(wrapper.find("submit")).toBe(true)
//   })
// })
//
//


import RequestCart from "components/RequestCart"
import { cartState, cartMutations, cartActions } from "store/cart/index"
import { render, fireEvent } from '@testing-library/vue'
import store from "store/index"

describe("RequestCart.vue", () => {
  test("Submitting cart", async () => {
    const customStore = {
      modules: {
        cart: {
          state: {
            items: [ {
              title: "My word"
            } ],
            isVisible: true
          },
          actions: cartActions,
          mutations: cartMutations
        }
      },
    }
    const { getByText, getByRole, container } = render(RequestCart, {
    // const { debug } = render(RequestCart, {
      store: { ...store, ...customStore },
      props: {
        configuration: {}
      }
    })

    console.log(container.textContent)
    const submitButton = getByRole("button")

    await fireEvent.click(submitButton)

    // expect post to config url toHaveBeenCalled()
    //   (need to use / stub axios I think)
    // expect items to be empty -- not sure how to get into store
    // need to actually submit the cart to see what happens -- you're taken to
    // an aeon site?
  })
})
