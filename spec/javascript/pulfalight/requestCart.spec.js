import RequestCart from "components/RequestCart"
import { cartMutations, cartActions } from "store/cart/index"
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
                AeonForm: "EADRequest",
                Request: ["1", "2"]
              }
            } ],
            isVisible: true
          },
          actions: cartActions,
          mutations: cartMutations
        }
      },
    }

    const { container } = render(RequestCart, {
      store: customStore,
      props: {
        configuration: {}
      }
    })

    const form = container.querySelector("form#request-cart-form")
    expect(form.querySelector("input[name='AeonForm'][value='EADRequest']")).not.toBe(null)
    expect(form.querySelector("input[name='Request'][value='1']")).not.toBe(null)
    expect(form.querySelector("input[name='Request'][value='2']")).not.toBe(null)

    const shadowForm = container.querySelector("form#shadow-form")
    const submitMock = jest.fn()
    shadowForm.addEventListener("submit", (event) => {
      // can't actually submit a form in a test
      event.preventDefault()
      submitMock()
    })

    await fireEvent.submit(form)

    // shadow form is populated
    expect(shadowForm.querySelector("input[name='AeonForm'][value='EADRequest']")).not.toBe(null)

    // shadow form was submitted
    expect(submitMock).toHaveBeenCalled()

    // cart is empty
    const button = container.querySelector("button[type='submit']")
    expect(button.textContent.trim()).toBe("No Items in Your Cart")
  })
})
