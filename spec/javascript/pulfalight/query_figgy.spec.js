import QueryFiggy from 'pulfalight/query_figgy'
import $ from 'jquery'
const createMockSuccessXHR = responseJSON => {
  const mockSuccessXHR = {
    open: jest.fn(),
    onreadystatechange: jest.fn(),
    readyState: 4,
    setRequestHeader: jest.fn(),
    status: 200,
    responseText: JSON.stringify({"data": {"resourcesByOrangelightId":
          [{"id":"78e15d09-3a79-4057-b358-4fde3d884bbb",
          "label":"Outlines and Notes",
          "sourceMetadataIdentifier":"C1491_c4",
          "url":"https://figgy.princeton.edu/catalog/78e15d09-3a79-4057-b358-4fde3d884bbb"}
          ]}})
  }
  mockSuccessXHR.send = jest.fn().mockImplementation(() => mockSuccessXHR.onreadystatechange())
  return mockSuccessXHR;
};

global.$ = $

describe('QueryFiggy', function() {
  const oldXMLHttpRequest = window.XMLHttpRequest;
  let mockSuccessXHR = null;
  let component_id = "c1491_c4";

  beforeEach(() => {
    mockSuccessXHR = createMockSuccessXHR();
    window.XMLHttpRequest = jest.fn(() => mockSuccessXHR);
  });

  afterEach(() => {
    window.XMLHttpRequest = oldXMLHttpRequest;
  });

  test('not to be undefined', () => {
    expect(QueryFiggy).not.toBe(undefined)
  })

  test('Adds the Log in button when they dont have permission to see the manifest in figgy', async () => {
    global.fetch = jest.fn(() =>
      Promise.resolve({status: 401})
    )
    document.body.innerHTML = '<div id="readingroom"></div>'
    const query = new QueryFiggy
    await query.checkFiggy(component_id);
    expect(mockSuccessXHR.send).toHaveBeenCalled();
    expect(document.getElementById('readingroom').innerHTML).toBe('<p>Access to this material is limited to specific classes. <button id="login" class="btn">Use your Princeton credentials to login.</button></p>')
  })

  test('Loads an iframe when they have permission to see the manifest in figgy', async () => {
    global.fetch = jest.fn(() =>
      Promise.resolve({status: 200})
    )
    document.body.innerHTML = '<div id="readingroom"></div>'
    const query = new QueryFiggy
    await query.checkFiggy(component_id);
    expect(mockSuccessXHR.send).toHaveBeenCalled();
    expect(document.querySelector('#readingroom iframe').getAttribute('src')).toBe('https://figgy.princeton.edu/viewer#?manifest=https://figgy.princeton.edu/concern/scanned_resources/78e15d09-3a79-4057-b358-4fde3d884bbb/manifest')
  })

  test("component_id() Capitalizes alphabetic characters before the underscore", () => {
    document.body.innerHTML = '<div id="document" class="document blacklight-file" itemscope="" itemtype="http://schema.org/Thing"><div id="doc_aspace_c1491_c4"></div></div>'
    const query = new QueryFiggy
    expect(query.component_id(component_id)).toEqual("C1491_c4")
  })
})
