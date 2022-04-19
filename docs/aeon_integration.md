# Aeon Integration

To allow users to request materials, Pulfalight submits a form to Aeon's
external request endpoint. This triggers an aeon login and the user can then manage their requests in the Aeon UI.

* [Aeon Documentation](https://support.atlas-sys.com/hc/en-us/articles/360011820054-External-Request-Endpoint). Note this documentation is not comprehensive, and a lot of what we do has been discovered through experience.
* [Technical Overview of EAD Requesting with Aeon](https://blog.rockarch.org/technical-overview-of-ead-requesting-with-aeon)

### The Aeon External Request Endpoint

The form has a few different types of fields: global fields and per-request
fields. Some of the global fields are Grouping Options.

Grouping Options allows you to define a grouping field (ours is the call number
and the box number) so that you can combine multiple requests into a single call
slip. For each of the other values you can then define whether you want them
concatenated or to just take the first value. Update [aeon_request.rb](https://github.com/pulibrary/pulfalight/blob/0cfda015d169ffdc34ddfeac81934382a147b307/app/values/aeon_request.rb#L174-L189) to change this logic.

Otherwise we mostly prefer per-request fields over global fields because we submit multiple requests at once.

### Implementation notes

The view accesses the form data via a method on the solr_document. Each cart
button is populated with the fields required to request that item. When all
items are requested all the fields are submitted. Relevant files in code:

* https://github.com/pulibrary/pulfalight/blob/a0fde8db6374ee3220d07f1f82f80de6c274c705/app/views/catalog/_show_tab_panes.html.erb#L7-L20
* https://github.com/pulibrary/pulfalight/blob/a0fde8db6374ee3220d07f1f82f80de6c274c705/app/models/solr_document.rb#L256-L258
* And lots of vue stuff

### Development / Testing / Troubleshooting tips

One way to see what's happening is to open the browser's inspector and check the
network tab to see exactly what's getting submitted to the Aeon.dll endpoint
when you click a cart's 'request items' button.

When troubleshooting you should cancel each request as you make it so none of them
are actually pulled and delivered. You can also put a note that it's a test.
There is a test user account we could try using, the creds for which are in
lastpass.

We can't mock the interaction with Aeon in tests, so specs just test that the
correct values are sent to the Aeon endpoint. We need to submit
an actual request manually when we make changes since we don't have automated end-to-end
testing of this feature.
