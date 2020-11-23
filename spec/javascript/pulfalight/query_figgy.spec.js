import QueryFiggy from 'pulfalight/query_figgy'

const createMockSuccessXHR = responseJSON => {
  const mockSuccessXHR = {
    open: jest.fn(),
    onreadystatechange: jest.fn(),
    send: jest.fn(),
    readyState: 4,
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
  let component_id = "C1491_c4";

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

  test('Should return a mockSuccessXHR when it finds the component_id in figgy', async () => {
    const reqPromise = QueryFiggy.checkFiggy(component_id);

    mockSuccessXHR.onreadystatechange();
    await jest.setTimeout(7000)
  })
})
