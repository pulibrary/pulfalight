//Attempt to get the element using document.getElementById
$( document ).ready(function() {
  // var q = document.getElementById("q");
  var q = $( ".home-header #q" )
  if(typeof(q) != 'undefined' && q != null){
      // Set focus on the search box if it exists
      q.focus();
  }
});
