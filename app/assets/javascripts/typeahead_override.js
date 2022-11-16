// Since the upstream file can't be overridden, here we un-do the setup done
// upstream and repeat the setup with hint: false
// see https://github.com/projectblacklight/blacklight/blob/v7.27.1/app/assets/javascripts/blacklight/blacklight.js#L57-L84
Blacklight.onLoad(function() {

  'use strict';

  $('[data-autocomplete-enabled="true"]').each(function() {
    var $el = $(this);
    var suggestUrl = $el.data().autocompletePath;

    // upstream code sets up typeahead and we don't want two of them
    if($el.hasClass('tt-input')) {
      $el.typeahead('destroy')
    }

    var terms = new Bloodhound({
      datumTokenizer: Bloodhound.tokenizers.obj.whitespace('value'),
      queryTokenizer: Bloodhound.tokenizers.whitespace,
      remote: {
        url: suggestUrl + '?q=%QUERY',
        wildcard: '%QUERY'
      }
    });

    terms.initialize();

    // set hint to false
    $el.typeahead({
      hint: false,
      highlight: true,
      minLength: 2
    },
    {
      name: 'terms',
      displayKey: 'term',
      source: terms.ttAdapter()
    });
  });
});
