import RequestCart from "components/RequestCart"
import { render, fireEvent } from '@testing-library/vue'

describe("RequestCart.vue", () => {
  test("Submitting cart", async () => {
    const store = {
      state: {
        cart: {
          items: [ {
            title: "My word"
          } ],
          isVisible: true
        }
      }
    }
    const { getByText, getByRole, container } = render(RequestCart, {
      store,
      props: {
        configuration: {}
      }})

    debugger;
    const submitButton = getByText("submit")

    await fireEvent.click(submitButton)

    // expect post to config url toHaveBeenCalled()
    //   (need to use / stub axios I think)
    // expect items to be empty -- not sure how to get into store
    // need to actually submit the cart to see what happens -- you're taken to
    // an aeon site?
  })
})
