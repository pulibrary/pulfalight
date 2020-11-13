import { render, fireEvent } from '@testing-library/vue'
import AddToCartButton from "components/AddToCartButton"

describe("AddToCartButton.vue", () => {
  test("Adding to cart", async () => {
    const addItemToCart = jest.fn()
    const store = {
      actions: {
        "addItemToCart": addItemToCart
      }
    }
    const { getByRole } = render(AddToCartButton, { store, props: { title: "Title", callnumber: "AC101" } })
    const button = getByRole("button")
    await fireEvent.click(button)
    expect(addItemToCart).toHaveBeenCalledWith(expect.anything(), {"callnumber": "AC101", "containers": "", "formParams": undefined, "title": "Title"})
  })
})
