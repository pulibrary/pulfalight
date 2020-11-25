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
              title: "My word",
              formParams: {
                AeonForm: "EADRequest"
              }
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

    const form = container.querySelector("form#request-cart-form")
    expect(form.querySelector("input[name='AeonForm'][value='EADRequest']")).not.toBe(null)

    const shadowForm = container.querySelector("form#shadow-form")
    const submitEvent = jest.fn()
    shadowForm.addEventListener("submit", (event) => {
      event.preventDefault()
      submitEvent()
    })

    await fireEvent.submit(form)

    // shadow form is populated
    expect(shadowForm.querySelector("input[name='AeonForm'][value='EADRequest']")).not.toBe(null)

    // shadow form was submitted
    expect(submitEvent).toHaveBeenCalled()

    // cart is empty
    const button = container.querySelector("button[type='submit']")
    expect(button.textContent.trim()).toBe("No Items in Your Cart")
  })
})
