// Setup jstree-based Table Of Contents
$(document).ready(function() {
  let element = $('#toc')
  if(element.length > 0) {
    let selectedId = element.data('selected')
    let baseUrl = element.data('url')
    let initialUrl = `${baseUrl}?node=${selectedId}&full=true`

    $(element).jstree({
      'core': {
        'themes': {
          'icons': false,
          'dots': false
        },
        'data' : {
          'url': function (node) {
            if (node.id === '#') {
              return initialUrl
            } else {
              return `${baseUrl}?node=${node.id}`
            }
          }
        }
      }
    });

    // Listen for click on the leaf node and follow link to component
    $(element)
    .on('activate_node.jstree', function (e, data) {
        let url = `/catalog/${data.node.id}`
        window.location.href = url
    })
  }
})
