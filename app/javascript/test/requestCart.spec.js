import RequestCart from '@/components/RequestCart.vue'
import { cartMutations, cartActions } from '@/store/cart/index.es6'
import { render, fireEvent } from '@testing-library/vue'
import { store } from '@/store/index.es6'
import { createStore } from 'vuex'
import { LuxInputButton, LuxInputText } from 'lux-design-system'
import { flushPromises } from '@vue/test-utils'

describe('RequestCart.vue', () => {
  test('Rendering locations', async () => {
    const customStore = {
      modules: {
        cart: {
          state: {
            items: [{
              title: 'My word',
              formParams: {
                AeonForm: 'EADRequest',
                WebRequestForm: 'EADRequest',
                Request: ['1', '2']
              },
              location: {
                notes: "It's far away",
                label: 'Mudd Manuscript Library',
                url: 'https://example.com'
              }
            }],
            isVisible: true
          },
          actions: cartActions,
          mutations: cartMutations
        }
      }
    }

    const mergedStore = createStore({ ...store, ...customStore })
    const { container } = render(RequestCart, {
      global: {
        plugins: [mergedStore]
      },
      store: customStore,
      props: {
        configuration: {},
        globalFormParams: {
          SystemID: 'Pulfa'
        }
      }
    })
    const notes = container.querySelector('.request__location-notes')
    expect(notes.textContent).toMatch("It's far away")
    const locationInfo = container.querySelector('.request__location')
    expect(locationInfo.textContent).toContain('This item can be viewed in person at Mudd Library.')
    expect(locationInfo.textContent).toContain('These item(s) will be paged upon your arrival to the reading room.')
    expect(locationInfo.querySelector('a').attributes.href.value).toBe('https://example.com')
  })
  test('Rendering locations with no url', async () => {
    const customStore = {
      modules: {
        cart: {
          state: {
            items: [{
              title: 'My word',
              formParams: {
                AeonForm: 'EADRequest',
                WebRequestForm: 'EADRequest',
                Request: ['1', '2']
              },
              location: {
                notes: "It's far away",
                label: 'Mudd Manuscript Library',
                url: null
              }
            }],
            isVisible: true
          },
          actions: cartActions,
          mutations: cartMutations
        }
      }
    }

    const mergedStore = createStore({ ...store, ...customStore })
    const { container } = render(RequestCart, {
      global: {
        plugins: [mergedStore]
      },
      props: {
        configuration: {},
        globalFormParams: {
          SystemID: 'Pulfa'
        }
      }
    })
    const notes = container.querySelector('.request__location-notes')
    expect(notes.textContent).toMatch("It's far away")
    const locationInfo = container.querySelector('.request__location')
    expect(locationInfo.textContent).toMatch('This item can be viewed in person at Mudd Library.')
    expect(locationInfo.querySelector('a')).toBe(null)
  })
  test('Submitting cart', async () => {
    const customStore = {
      modules: {
        cart: {
          state: {
            items: [{
              title: 'My word',
              formParams: {
                AeonForm: 'EADRequest',
                WebRequestForm: 'EADRequest',
                Request: ['1', '2']
              }
            }],
            isVisible: true
          },
          actions: cartActions,
          mutations: cartMutations
        }
      }
    }

    const mergedStore = createStore({ ...store, ...customStore })
    const { container } = render(RequestCart, {
      global: {
        plugins: [mergedStore],
        components: {
          'lux-input-button': LuxInputButton,
          'lux-input-text': LuxInputText
        }
      },
      props: {
        configuration: {},
        globalFormParams: {
          SystemID: 'Pulfa'
        }
      }
    })

    const form = container.querySelector('form#request-cart-form')
    expect(form.querySelector("input[name='AeonForm'][value='EADRequest']")).not.toBe(null)
    expect(form.querySelector("input[name='WebRequestForm'][value='EADRequest']")).not.toBe(null)
    expect(form.querySelector("input[name='Request'][value='1']")).not.toBe(null)
    expect(form.querySelector("input[name='Request'][value='2']")).not.toBe(null)
    const noteInput = form.querySelector("textarea[name='Notes']")
    noteInput.value = 'Test Note'

    const shadowForm = container.querySelector('form#shadow-form')
    let submittedForm = null
    const submitMock = function () {
      submittedForm = this
    }
    window.HTMLFormElement.prototype.submit = submitMock

    await fireEvent.submit(form)

    // shadow form is populated
    expect(shadowForm.querySelector("input[name='SystemID'][value='Pulfa']")).not.toBe(null)
    expect(shadowForm.querySelector("input[name='AeonForm'][value='EADRequest']")).not.toBe(null)
    expect(shadowForm.querySelector("input[name='WebRequestForm'][value='EADRequest']")).not.toBe(null)
    expect(shadowForm.querySelector("input[name='Notes']")).not.toBe(null)

    // shadow form was submitted
    expect(submittedForm.id).toBe('shadow-form')

    // cart is empty
    const button = container.querySelector("button[type='submit']")
    expect(button.textContent.trim()).toBe('No Items in Your Cart')
  })
  test('pressing escape closes the cart', async () => {
    const customStore = {
      modules: {
        cart: {
          state: {
            items: [],
            isVisible: true
          },
          actions: cartActions,
          mutations: cartMutations
        }
      }
    }
    const mergedStore = createStore({ ...store, ...customStore })
    const { container } = render(RequestCart, {
      global: {
        plugins: [mergedStore],
        components: {
          'lux-input-button': LuxInputButton,
          'lux-input-text': LuxInputText
        }
      },
      props: {
        configuration: {},
        globalFormParams: {
          SystemID: 'Pulfa'
        }
      }
    })
    const cart = container.querySelector('.request-cart')
    expect(cart).not.toBe(null)
    await fireEvent.keyDown(cart, { key: 'Escape' })
    expect(container.querySelector('.request-cart[open]')).toBe(null)
  })
  test('click outside of the cart closes the cart', async () => {
    const customStore = {
      modules: {
        cart: {
          state: {
            items: [],
            isVisible: false
          },
          actions: cartActions,
          mutations: cartMutations
        }
      }
    }
    const mergedStore = createStore({ ...store, ...customStore })
    const { container } = render(RequestCart, {
      global: {
        plugins: [mergedStore],
        components: {
          'lux-input-button': LuxInputButton,
          'lux-input-text': LuxInputText
        }
      },
      props: {
        configuration: {},
        globalFormParams: {
          SystemID: 'Pulfa'
        }
      }
    })
    expect(container.querySelector('.request-cart[open]')).toBeFalsy()

    document.dispatchEvent(new Event('TOGGLE_CART'))
    await flushPromises()
    expect(container.querySelector('.request-cart[open]')).toBeTruthy()

    await fireEvent.click(container.querySelector('dialog'))
    expect(container.querySelector('.request-cart[open]')).toBeFalsy()
  })

  test('it opens the cart when it hears the OPEN_CART event', async () => {
    const customStore = {
      modules: {
        cart: {
          state: {
            items: [],
            isVisible: false
          },
          actions: cartActions,
          mutations: cartMutations
        }
      }
    }
    const mergedStore = createStore({ ...store, ...customStore })
    const { container } = render(RequestCart, {
      global: {
        plugins: [mergedStore],
        components: {
          'lux-input-button': LuxInputButton,
          'lux-input-text': LuxInputText
        }
      },
      props: {
        configuration: {},
        globalFormParams: {
          SystemID: 'Pulfa'
        }
      }
    })
    expect(container.querySelector('.request-cart[open]')).toBeFalsy()

    document.dispatchEvent(new Event('OPEN_CART'))
    await flushPromises()
    expect(container.querySelector('.request-cart[open]')).toBeTruthy()
  })
})
