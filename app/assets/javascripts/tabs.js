$( document ).ready(function() {
  const url = new URL(window.location);

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

  $(".lux-tabs-container li").click(function( event ) {
    event.preventDefault();
    $(".lux-tabs-container li").removeClass( "active" );
    $(".tab-pane").removeClass( "active" );
    $("#toc .jstree-clicked").removeClass( "jstree-clicked" );
    switch (event.currentTarget.id) {
      case 'summary-tab':
        $( "#summary-tab" ).addClass( "active" );
        $( "#summary" ).addClass( "active" );
        break;
      case 'description-tab':
        $( "#description-tab" ).addClass( "active" );
        $( "#description" ).addClass( "active" );
        break;
      case 'collection-history-tab':
        $( "#collection-history-tab" ).addClass( "active" );
        $( "#collection-history" ).addClass( "active" );
        break;
      case 'access-tab':
        $( "#access-tab" ).addClass( "active" );
        $( "#access" ).addClass( "active" );
        break;
      case 'find-more-tab':
        $( "#find-more-tab" ).addClass( "active" );
        $( "#find-more" ).addClass( "active" );
        break;
      default:
        $( "#summary-tab" ).addClass( "active" );
    }
  });
});
