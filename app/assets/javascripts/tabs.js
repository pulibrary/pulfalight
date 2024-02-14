function isCollectionLandingPage(url) {
  // If there's an underscore it's a component page
  if(url.href.includes("_"))
    return false;
  // If there's a component summary it's a component page.
  else if($("#component-summary").length > 0)
    return false;
  else
    return true;
}
$( document ).ready(function() {
  const url = new URL(window.location);
  $(".lux-tabs-container li").removeClass( "active" );
  // Default to summary tab if it's a collection landing page.
  if(!url.hash && isCollectionLandingPage(url)){
    url.hash = '#summary';
  }
  switch (url.hash) {
    case '#summary':

      $( "#summary-tab" ).addClass( "active" );
      $( "#summary" ).addClass( "active" );
      break;
    case '#description':
      $( "#description-tab" ).addClass( "active" );
      $( "#description" ).addClass( "active" );
      break;
    case '#collection-history':
      $( "#collection-history-tab" ).addClass( "active" );
      $( "#collection-history" ).addClass( "active" );
      break;
    case '#access':
      $( "#access-tab" ).addClass( "active" );
      $( "#access" ).addClass( "active" );
      break;
    case '#find-more':
      $( "#find-more-tab" ).addClass( "active" );
      $( "#find-more" ).addClass( "active" );
      break;
    default:
      $( "#component-summary" ).addClass( "active" );
  }

  // The following code is a temporary fix.
  // Working code for a tab-based approach can be found here:
  // https://github.com/pulibrary/pulfalight/blob/i674/app/assets/javascripts/tabs.js#L38-L67

  $(".lux-tabs-container li").click(function() {
    let temp_url = window.location.split("-");
    temp_url.pop()
    let temp_id = $(this).attr('id').split("-");
    window.location = temp_id.pop()
    window.location.hash = temp_id.join("-");
  });

  // prevents auto scrolling to anchor points
  if (url.hash) {
    setTimeout(function() {
      window.scrollTo(0, 0);
    }, 1);
  }

  // allows browser back/forward button use
  $(window).on('popstate',function(event) {
    window.location = document.location;
    window.location.reload();
  });

});
