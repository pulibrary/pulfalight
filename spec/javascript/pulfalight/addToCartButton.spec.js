import { render, fireEvent } from '@testing-library/vue'
import AddToCartButton from "components/AddToCartButton"
import { store } from "store"

// Copied from example at
// https://github.com/testing-library/vue-testing-library/blob/master/src/__tests__/vuex.js
function renderVuexTestComponent(customStore, props, slot) {
  // Render the component and merge the original store and the custom one
  // provided as a parameter. This way, we can alter some behaviors of the
  // initial implementation.
  return render(AddToCartButton, {store: {...store, ...customStore}, props: props, slot: slot})
}

describe("AddToCartButton.vue", () => {
  test("Adding to cart", () => {
    const addItemToCart = jest.fn()
    const store = {
      actions: {
        addItemToCart: () => addItemToCart
      },
    }
    const { getByRole } = renderVuexTestComponent(null, { title: "Title", callnumber: "AC101" })
    expect(getByRole("button")).not.toBeNull
  })
})
