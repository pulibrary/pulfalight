import { render, fireEvent } from '@testing-library/vue'
import { store } from '@/store/index.es6'
import { createStore } from 'vuex'
import AddToCartButton from '@/components/AddToCartButton.vue'

describe('AddToCartButton.vue', () => {
  test('Adding to cart', async () => {
    const addItemToCart = vi.fn()
    const newStore = {
      actions: {
        addItemToCart
      }
    }
    const mergedStore = createStore({ ...store, ...newStore })
    const { getByRole } = render(AddToCartButton, {
      global: {
        plugins: [mergedStore]
      },
      props: { title: 'Title', callnumber: 'AC101' }
    })
    const button = getByRole('button')
    await fireEvent.click(button)
    expect(addItemToCart).toHaveBeenCalledWith(expect.anything(), { accessRestrict: '', callnumber: 'AC101', containers: '', formParams: undefined, title: 'Title' })
  })
})
