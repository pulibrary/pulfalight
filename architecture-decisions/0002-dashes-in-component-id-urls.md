# 2. Dashes in Component ID URLs

Date: 2022-01-20

## Status

Accepted

## Context

Some EADs in ArchivesSpace are split into multiple EADs for performance. Their
call numbers are split by a period - for example, `MC001.01` and `MC001.02`. A
component in one of these might be `MC001.01_c000001`.

We use the component IDs as the document ID in Solr, and the path for the
catalog record page. Unfortunately, Blacklight's not built to handle periods in
solr document IDs and customizing it to do so would potentially be quite
complicated.

## Decision

For IDs with periods we replace the periods with a `-` for the URL. This means
the record page for `MC001.01_c000001` is
`https://findingaids.princeton.edu/catalog/MC001-01_c000001`. The proper component
ID will be embedded in the HTML as a data element `data-component-id` for
Javascript to act on.

The component ID with the period should still be used in ArchivesSpace and
Figgy. It will only change the URL and the ID of the Solr document.

## Consequences

1. The component ID can't be directly copied from the URL of the record page
   into Figgy directly. We can maybe automatically convert a "dash component ID"
   in Figgy if it's entered.
