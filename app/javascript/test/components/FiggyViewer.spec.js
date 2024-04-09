import FiggyViewer from "@/components/FiggyViewer.vue"
import { mount } from '@vue/test-utils'
import flushPromises from 'flush-promises'

describe("FiggyViewer.vue", () => {
  function stubQuery(embedHash) {
    global.fetch = vi.fn(() =>
      Promise.resolve({
        status: 200,
        json: () => Promise.resolve(
          {
            "data": {
              "resourcesByOrangelightId": [
                {
                  "id": component_id,
                  "embed": embedHash
                }
              ]
            }
          }
        )
      })
    )
  }

  let component_id = "c1491_c4";

  test("Adds the Log in button when embed status is unauthenticated and there's no content", async () => {
    stubQuery({
      "type": null,
      "content": null,
      "status": "unauthenticated"
    })

    const wrapper = await mount(FiggyViewer, {
      propsData: {
        componentId: component_id,
        daoLabel: "",
        daoLink: ""
      }
    })

    await flushPromises()

    expect(wrapper.html()).toContain('Use your Princeton credentials to login.')
  })

  test("Logging in can switch content to a link", async () => {

    stubQuery({
      "type": null,
      "content": null,
      "status": "unauthenticated"
    })

    const wrapper = await mount(FiggyViewer, {
      propsData: {
        componentId: component_id,
        daoLabel: "",
        daoLink: ""
      }
    })

    await flushPromises()

    stubQuery({
      "type": "link",
      "content": "https://figgy.princeton.edu/download/something/file/78e15d09-3a79-4057-b358-4fde3d884bbb",
      "status": "authorized"
    })

    // updateData is called by the login window closing.
    await wrapper.vm.updateData()
    await flushPromises()

    expect(wrapper.vm.embedStatus).toBe("authorized")

    expect(wrapper.element.querySelector('a').getAttribute('href')).toBe('https://figgy.princeton.edu/download/something/file/78e15d09-3a79-4057-b358-4fde3d884bbb')
    expect(wrapper.element.querySelector('a').innerHTML).toBe('Download Content')
  })


  test('Loads an iframe when they have permission to see the manifest in figgy', async () => {
    stubQuery({
      "type": "html",
      "content": "<iframe src='https://figgy.princeton.edu/viewer#?manifest=https://figgy.princeton.edu/concern/scanned_resources/78e15d09-3a79-4057-b358-4fde3d884bbb/manifest'></iframe>",
      "status": "authorized"
    })

    const wrapper = await mount(FiggyViewer, {
      propsData: {
        componentId: component_id,
        daoLabel: "",
        daoLink: ""
      }
    })

    await flushPromises()

    expect(wrapper.element.querySelector('iframe').getAttribute('src')).toBe('https://figgy.princeton.edu/viewer#?manifest=https://figgy.princeton.edu/concern/scanned_resources/78e15d09-3a79-4057-b358-4fde3d884bbb/manifest')
  })

  test('When there was no DAO, embed type is link, and status is authorized, loads a link', async () => {
    stubQuery({
      "type": "link",
      "content": "https://figgy.princeton.edu/download/something/file/78e15d09-3a79-4057-b358-4fde3d884bbb",
      "status": "authorized"
    })

    const wrapper = await mount(FiggyViewer, {
      propsData: {
        componentId: component_id,
        daoLabel: "",
        daoLink: ""
      }
    })

    await flushPromises()

    expect(wrapper.element.querySelector('a').getAttribute('href')).toBe('https://figgy.princeton.edu/download/something/file/78e15d09-3a79-4057-b358-4fde3d884bbb')
    expect(wrapper.element.querySelector('a').innerHTML).toBe('Download Content')
  })

  test("When there was a DAO, embed type is link, and status is authorized, loads a link with dao's label", async () => {
    stubQuery({
      "type": "link",
      "content": "https://figgy.princeton.edu/download/something/file/78e15d09-3a79-4057-b358-4fde3d884bbb",
      "status": "authorized"
    })

    const wrapper = await mount(FiggyViewer, {
      propsData: {
        componentId: component_id,
        daoLabel: "Download Zip File",
        daoLink: "https://figgy.princeton.edu/download/something/file/78e15d09-3a79-4057-b358-4fde3d884bbb"
      }
    })

    await flushPromises()

    expect(wrapper.element.querySelector('a').getAttribute('href')).toBe('https://figgy.princeton.edu/download/something/file/78e15d09-3a79-4057-b358-4fde3d884bbb')
    expect(wrapper.element.querySelector('a').innerHTML).toBe('Download Zip File')
  })

  test("When there was a DAO with the wrong url and embed type is link it adds a download link to the one from Figgy", async () => {

    stubQuery({
      "type": "link",
      "content": "https://figgy.princeton.edu/download/something/file/78e15d09-3a79-4057-b358-4fde3d884bbb",
      "status": "authorized"
    })

    const wrapper = await mount(FiggyViewer, {
      propsData: {
        componentId: component_id,
        daoLabel: "Download Zip File",
        daoLink: "https://figgy.princeton.edu/download/something/file/verywrong"
      }
    })

    await flushPromises()

    expect(wrapper.element.querySelector('a').getAttribute('href')).toBe('https://figgy.princeton.edu/download/something/file/78e15d09-3a79-4057-b358-4fde3d884bbb')
    expect(wrapper.element.querySelector('a').innerHTML).toBe('Download Content')
  })

  test('When embed status is unauthorized, nothing gets rendered', async () => {
    stubQuery({
      "type": null,
      "content": null,
      "status": "unauthorized"
    })

    const wrapper = await mount(FiggyViewer, {
      propsData: {
        componentId: component_id,
        daoLabel: "Download Zip File",
        daoLink: "https://figgy.princeton.edu/download/something/file/verywrong"
      }
    })

    await flushPromises()

    expect(wrapper.text()).toBe('')
  })
})
