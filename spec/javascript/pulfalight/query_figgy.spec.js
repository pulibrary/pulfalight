import QueryFiggy from 'pulfalight/query_figgy'
import $ from 'jquery'

global.$ = $

describe('QueryFiggy', function() {
  let component_id = "c1491_c4";

  test('not to be undefined', () => {
    expect(QueryFiggy).not.toBe(undefined)
  })

  function stubQuery(embedHash) {
    global.fetch = jest.fn(() =>
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

  test("Adds the Log in button when embed status is unauthenticated and there's no content", async () => {
    stubQuery({
      "type": null,
      "content": null,
      "status": "unauthenticated"
    })
    document.body.innerHTML = '<div id="readingroom" data-dao-label="" data-dao-link=""></div>'
    const query = new QueryFiggy
    await query.checkFiggy(component_id);
    expect(document.getElementById('readingroom').innerHTML).toBe('<p>Please contact Special Collections staff through the <a href="https://library.princeton.edu/special-collections/ask-us">Ask Us! form</a> for access to this collection. <button id="login" class="btn">Use your Princeton credentials to login.</button></p>')
  })

  test('Loads an iframe when they have permission to see the manifest in figgy', async () => {
    stubQuery({
      "type": "html",
      "content": "<iframe src='https://figgy.princeton.edu/viewer#?manifest=https://figgy.princeton.edu/concern/scanned_resources/78e15d09-3a79-4057-b358-4fde3d884bbb/manifest'></iframe>",
      "status": "authorized"
    })
    // whether or not there's a dao, we don't use these data values in this case
    document.body.innerHTML = '<div id="readingroom" data-dao-label="" data-dao-link=""></div>'
    const query = new QueryFiggy
    await query.checkFiggy(component_id);
    expect(document.querySelector('#readingroom iframe').getAttribute('src')).toBe('https://figgy.princeton.edu/viewer#?manifest=https://figgy.princeton.edu/concern/scanned_resources/78e15d09-3a79-4057-b358-4fde3d884bbb/manifest')
  })

  test('When there was no DAO, embed type is link, and status is authorized, loads a link', async () => {
    stubQuery({
      "type": "link",
      "content": "https://figgy.princeton.edu/download/something/file/78e15d09-3a79-4057-b358-4fde3d884bbb",
      "status": "authorized"
    })
    document.body.innerHTML = '<div id="readingroom" data-dao-label="" data-dao-link=""></div>'
    const query = new QueryFiggy
    await query.checkFiggy(component_id);
    expect(document.querySelector('#readingroom a').getAttribute('href')).toBe('https://figgy.princeton.edu/download/something/file/78e15d09-3a79-4057-b358-4fde3d884bbb')
    expect(document.querySelector('#readingroom a').innerHTML).toBe('Download Content')
  })

  test("When there was a DAO, embed type is link, and status is authorized, loads a link with dao's label", async () => {
    stubQuery({
      "type": "link",
      "content": "https://figgy.princeton.edu/download/something/file/78e15d09-3a79-4057-b358-4fde3d884bbb",
      "status": "authorized"
    })
    document.body.innerHTML = '<div id="readingroom" data-dao-label="Download Zip File" data-dao-link="https://figgy.princeton.edu/download/something/file/78e15d09-3a79-4057-b358-4fde3d884bbb"></div>'
    const query = new QueryFiggy
    await query.checkFiggy(component_id);
    expect(document.querySelector('#readingroom a').getAttribute('href')).toBe('https://figgy.princeton.edu/download/something/file/78e15d09-3a79-4057-b358-4fde3d884bbb')
    expect(document.querySelector('#readingroom a').innerHTML).toBe('Download Zip File')
  })

  test("When there was a DAO with the wrong url and embed type is link it adds a download link to the one from Figgy", async () => {
    stubQuery({
      "type": "link",
      "content": "https://figgy.princeton.edu/download/something/file/78e15d09-3a79-4057-b358-4fde3d884bbb",
      "status": "authorized"
    })
    document.body.innerHTML = '<div id="readingroom" data-dao-label="Download Zip File" data-dao-link="https://figgy.princeton.edu/download/something/file/verywrong"></div>'
    const query = new QueryFiggy
    await query.checkFiggy(component_id);
    expect(document.querySelector('#readingroom a').getAttribute('href')).toBe('https://figgy.princeton.edu/download/something/file/78e15d09-3a79-4057-b358-4fde3d884bbb')
    expect(document.querySelector('#readingroom a').innerHTML).toBe('Download Content')
  })

  test('When embed status is unauthorized, nothing gets rendered', async () => {
    stubQuery({
      "type": null,
      "content": null,
      "status": "unauthorized"
    })
    document.body.innerHTML = '<div id="readingroom" data-dao-label="" data-dao-link=""></div>'
    const query = new QueryFiggy
    await query.checkFiggy(component_id);
    expect(document.querySelector('#readingroom').innerHTML).toBe('')
  })

  test("component_id() Capitalizes alphabetic characters before the underscore", () => {
    document.body.innerHTML = '<div id="document" class="document blacklight-file" itemscope="" itemtype="http://schema.org/Thing"><div data-component-id="C1491_c4"></div></div>'
    const query = new QueryFiggy
    expect(query.component_id(component_id)).toEqual("C1491_c4")
  })
})
