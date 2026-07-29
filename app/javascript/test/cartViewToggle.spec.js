import CartViewToggle from '@/components/CartViewToggle.vue'
import { render, fireEvent } from '@testing-library/vue'
import { store } from '@/store/index.es6'
import { createStore } from 'vuex'

describe('CartViewToggle.vue', () => {
  test('Toggling cart', async () => {
    let cartToggled = false
    document.addEventListener('TOGGLE_CART', () => { cartToggled = true })
    const newStore = {
      state: {
        cart: {
          items: [{}]
        }
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
    expect(cartToggled).toBe(true)

    const count = container.getElementsByClassName('badge')[0]
    expect(count.querySelector('[aria-hidden="true"]').textContent.trim()).toBe('1')
    expect(count.querySelector('.sr-only').textContent.trim()).toBe('1 item in request cart')
  })

  test('Pluralizes the screen reader item count', async () => {
    const newStore = {
      state: {
        cart: {
          items: [{}, {}]
        }
      }
    }
    const mergedStore = createStore({ ...store, ...newStore })
    const { container } = render(CartViewToggle, {
      global: {
        plugins: [mergedStore]
      }
    })

    const count = container.getElementsByClassName('badge')[0]
    expect(count.querySelector('.sr-only').textContent.trim()).toBe('2 items in request cart')
  })
})
