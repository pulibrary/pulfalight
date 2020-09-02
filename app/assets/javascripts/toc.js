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
          data: data,
          onCreateLi: function(node, $li) {
              var $button = $li.children(".jqtree-element").find("a.jqtree-toggler");
              $button.attr("href", "/catalog/" + node.id );
              var $title = $li.children(".jqtree-element").find("span.jqtree-title");
              $title.attr("id", node.id);
          }
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

    $(element).on('keypress',function(event) {
      console.log(event)
      if(event.which == 13) {
        let node = event.target
        let url = `/catalog/${node.id}`
        window.location.href = url
      }
    });
  }
})
