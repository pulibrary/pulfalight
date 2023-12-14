import RequestCart from "components/RequestCart"
import { cartMutations, cartActions } from "store/cart/index"
import { render, fireEvent } from '@testing-library/vue'

describe("RequestCart.vue", () => {
  test("Rendering locations", async () => {
    const customStore = {
      modules: {
        cart: {
          state: {
            items: [ {
              title: "My word",
              formParams: {
                AeonForm: "EADRequest",
            		WebRequestForm: "EADRequest",
                Request: ["1", "2"]
              },
              location: {
                notes: "It's far away",
                label: "Firestone Library",
                url: "https://example.com"
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
    const notes = container.querySelector(".request__location-notes")
    expect(notes.textContent).toMatch("It's far away")
    const locationInfo = container.querySelector(".request__location")
    expect(locationInfo.textContent).toMatch("View this item at the Firestone Library")
    expect(locationInfo.querySelector("a").attributes["href"].value).toBe("https://example.com")
  })
  test("Rendering locations with no url", async () => {
    const customStore = {
      modules: {
        cart: {
          state: {
            items: [ {
              title: "My word",
              formParams: {
                AeonForm: "EADRequest",
		            WebRequestForm: "EADRequest",
                Request: ["1", "2"]
              },
              location: {
                notes: "It's far away",
                label: "Firestone Library",
                url: null
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
    const notes = container.querySelector(".request__location-notes")
    expect(notes.textContent).toMatch("It's far away")
    const locationInfo = container.querySelector(".request__location")
    expect(locationInfo.textContent).toMatch("View this item at the Firestone Library")
    expect(locationInfo.querySelector("a")).toBe(null)
  })
  test("Submitting cart", async () => {
    const customStore = {
      modules: {
        cart: {
          state: {
            items: [ {
              title: "My word",
              formParams: {
                AeonForm: "EADRequest",
		            WebRequestForm: "EADRequest",
                Request: ["1", "2"]
              },
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
        configuration: {},
        globalFormParams: {
          "SystemID": "Pulfa"
        }
      }
    })

    const form = container.querySelector("form#request-cart-form")
    expect(form.querySelector("input[name='AeonForm'][value='EADRequest']")).not.toBe(null)
    expect(form.querySelector("input[name='WebRequestForm'][value='EADRequest']")).not.toBe(null)
    expect(form.querySelector("input[name='Request'][value='1']")).not.toBe(null)
    expect(form.querySelector("input[name='Request'][value='2']")).not.toBe(null)
    const noteInput = form.querySelector("textarea[name='Notes']")
    noteInput.value = "Test Note"

    const shadowForm = container.querySelector("form#shadow-form")
    const submitMock = jest.fn()
    shadowForm.addEventListener("submit", (event) => {
      // can't actually submit a form in a test
      event.preventDefault()
      submitMock()
    })

    await fireEvent.submit(form)

    // shadow form is populated
    expect(shadowForm.querySelector("input[name='SystemID'][value='Pulfa']")).not.toBe(null)
    expect(shadowForm.querySelector("input[name='AeonForm'][value='EADRequest']")).not.toBe(null)
    expect(shadowForm.querySelector("input[name='WebRequestForm'][value='EADRequest']")).not.toBe(null)
    expect(shadowForm.querySelector("input[name='Notes']")).not.toBe(null)

    // shadow form was submitted
    expect(submitMock).toHaveBeenCalled()

    // cart is empty
    const button = container.querySelector("button[type='submit']")
    expect(button.textContent.trim()).toBe("No Items in Your Cart")
  })
})
