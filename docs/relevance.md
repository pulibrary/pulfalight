# Search results and relevance ranking

Some documentation about existing use cases relevance ranking is helpful when
new requests come in to make changes to relevance. We
want to ensure any work we do to address new requirements leaves
previously-implemented requirements fully functional.

This documentation does not cover issues about records that didn't appear in
search results because certain fields weren't indexed at all or weren't indexed into the
correct type of field.

[Closed issues with Search Results label](https://github.com/pulibrary/pulfalight/issues?q=label%3A%22Search+Results%22+is%3Aclosed)

## Current relevance functionality

* [#146](https://github.com/pulibrary/pulfalight/issues/146), [#560](https://github.com/pulibrary/pulfalight/issues/560), [#982](https://github.com/pulibrary/pulfalight/issues/982) Any collection title that contains the search terms should have prioritized ranking, and if the collection title starts with the search terms, it should have highest ranking.
  * For example, a search for `John Foster Dulles` should put the John Foster Dulles Collection at the top
* [#557](https://github.com/pulibrary/pulfalight/issues/557) A keyword search for a name should only return results that match the name completely
  * For example, a search for `Frederick Vinton` should have a small result set, only returning records containing both words
* [#558](https://github.com/pulibrary/pulfalight/issues/558) A keyword search for a quoted phrase should return results where the words in that phrase are in a different order
  * For example, a search for `"Frederick Vinton"` should return results containing "Vinton, Frederick"
