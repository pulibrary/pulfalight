$(document).ready(function() {
  let element = $('#toc')
  if(element.length > 0) {
    let selectedId = element.data('selected')
    let baseUrl = element.data('url')
    let initialUrl = `${baseUrl}?node=${selectedId}&full=true`

    $.getJSON(
      initialUrl,
      function(data) {
        element.tree({
          data: data
        });
      }).done(function() {
        let selectedNode = element.tree('getNodeById', selectedId);
        element.tree('selectNode', selectedNode);
    });

    $(element).on(
      'tree.click',
      function(event) {
          let node = event.node
          let url = `/catalog/${node.id}`
          window.location.href = url
      }
    );
  }
})
