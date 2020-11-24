import RequestCart from "components/RequestCart"
import { cartState, cartMutations, cartActions } from "store/cart/index"
import { render, fireEvent } from '@testing-library/vue'

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
    const { getByRole, getByTestId, container } = render(RequestCart, {
      store: customStore,
      props: {
        configuration: {}
      }
    })

    const form = container.querySelector("form")
    await fireEvent.submit(form)

    const button = container.querySelector("button[type='submit']")
    expect(button.textContent.trim()).toBe("No Items in Your Cart")
  })
})
