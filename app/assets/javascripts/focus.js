$( document ).ready(function() {
  var q = $( ".home-header #q" )
  if(typeof(q) != 'undefined' && q != null){
      // Set focus on the search box if it exists
      q.focus();
  }
});
