import QueryFiggy from 'pulfalight/query_figgy'

const createMockSuccessXHR = responseJSON => {
  const mockSuccessXHR = {
    open: jest.fn(),
    onreadystatechange: jest.fn(),
    send: jest.fn(),
    readyState: 4,
    setRequestHeader: jest.fn(),
    responseText: JSON.stringify({"resourcesByOrangelightId":
          [{"id":"78e15d09-3a79-4057-b358-4fde3d884bbb",
          "label":"Outlines and Notes",
          "sourceMetadataIdentifier":"C1491_c4",
          "url":"https://figgy.princeton.edu/catalog/78e15d09-3a79-4057-b358-4fde3d884bbb"}
          ]})
  }
  return mockSuccessXHR;
};

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

  test('Adds the Log in button when it finds the component_id in figgy', async () => {
    const query = new QueryFiggy
    const reqPromise = query.checkFiggy(component_id);

    expect(mockSuccessXHR.send).toHaveBeenCalled();
    await jest.setTimeout(7000)
  })

  test("component_id() Capitalizes alphabetic characters before the underscore", () => {
    document.body.innerHTML = '<div id="document" class="document blacklight-file" itemscope="" itemtype="http://schema.org/Thing"><div id="doc_aspace_c1491_c4"></div></div>'
    const query = new QueryFiggy
    expect(query.component_id(component_id)).toEqual("C1491_c4")
  })
})
