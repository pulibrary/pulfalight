import CartViewToggle from '@/components/CartViewToggle.vue'
import { render, fireEvent } from '@testing-library/vue'
import { store } from '@/store/index.es6'
import { createStore } from 'vuex'

describe('CartViewToggle.vue', () => {
  test('Toggling cart', async () => {
    const toggleVisibility = vi.fn()
    const newStore = {
      state: {
        cart: {
          items: [{}]
        }
      },
      mutations: {
        TOGGLE_VISIBILITY: toggleVisibility
      }
    }
    const mergedStore = createStore({ ...store, ...newStore })
    const { getByRole, container } = render(CartViewToggle, {
      global: {
        plugins: [mergedStore]
      }
    })
    const button = getByRole('button')
    await fireEvent.click(button)
    expect(toggleVisibility).toHaveBeenCalled()

    const count = container.getElementsByClassName('badge')[0]
    expect(count.textContent.trim()).toBe('1')
  })
})
