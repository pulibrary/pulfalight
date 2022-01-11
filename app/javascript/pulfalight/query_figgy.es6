export default class {

  addLoginLink() {
    let readingRoom = document.getElementById("readingroom")
    let cssStyle = "border-radius: 3px; background: #fee7ba; padding: 20px; margin-bottom: 2em;"
    this.addStyle(readingRoom, cssStyle)
    readingRoom.innerHTML = "<p>Please contact Special Collections staff through the <a href='https://library.princeton.edu/special-collections/ask-us'>Ask Us! form</a> for access to this collection. <button id='login' class='btn' >Use your Princeton credentials to login.</button></p>";
    $('#readingroom #login').click(this.login)
  }

  addStyle(el, cssStyle) {
    el.setAttribute("style", cssStyle)
  }

  removeLoginLink() {
    let readingRoom = document.getElementById("readingroom")
    readingRoom.innerHTML = "";
    readingRoom.style.display = 'none';
  }

  login() {
    let child = window.open('https://figgy.princeton.edu/users/auth/cas?login_popup=true')

    const checkChild = () => {
      if (child.closed) {
        clearInterval(timer)
        window.location.reload()
      }
    }
    let timer = setInterval(checkChild, 200)
  }

  constructIframe(manifestURL) {
    const iframeElement = document.createElement("iframe")
    const figgyUrl = 'https://figgy.princeton.edu/'
    iframeElement.setAttribute("allowFullScreen", "true")
    iframeElement.id = 'uv_iframe'
    const src = "https://figgy.princeton.edu/viewer#?manifest=" + manifestURL
    iframeElement.src = src;

    return iframeElement;
  }

  constructViewerElement(manifestURL) {
    const viewerElement = document.createElement("div")
    viewerElement.setAttribute("class", "intrinsic-container intrinsic-container-16x9")
    viewerElement.id = 'uv_div'
    viewerElement.classList.add('uv__overlay')
    const iFrameElement = this.constructIframe(manifestURL)
    viewerElement.appendChild(iFrameElement)

    return viewerElement;
  }

  uppercaseChar(str,underscorePosition) {
    let component_id_upperCase = ''
    for (let i = 0; i < underscorePosition; i++) {
      component_id_upperCase += str.charAt(i).toUpperCase();
    }
    return component_id_upperCase;
  }

  component_id() {
    let doc_aspace_component_id = document.getElementById('document').getElementsByTagName('div')[0]
    let component_id = doc_aspace_component_id.getAttribute('id').replace('doc_', '')
    let underscorePosition = component_id.indexOf('_')
    component_id = this.uppercaseChar(component_id,underscorePosition) + component_id.slice(underscorePosition)
    return component_id;
  }

  checkFiggy(component_id) {
    var xhr = new XMLHttpRequest();
    var url = "https://figgy.princeton.edu/graphql";
    const that = this;
    xhr.open("POST", url, true);
    xhr.setRequestHeader("Content-Type", "application/json");
    xhr.onreadystatechange = function () {
        if (xhr.readyState === 4){
          if(xhr.status === 200) {
            var json = JSON.parse(xhr.responseText);
            if (json.data.resourcesByOrangelightId === undefined || json.data.resourcesByOrangelightId.length == 0) {
              that.removeLoginLink();
            } else {
              var figgy_id = json.data.resourcesByOrangelightId[0].id;
              var manifestURL = "https://figgy.princeton.edu/concern/scanned_resources/" + figgy_id + "/manifest"

              return fetch(manifestURL, {credentials: 'include'}).then(function(response) {
                if(response.status == 401) { that.addLoginLink() } else if(response.status == 200) { that.renderReadingRoom(manifestURL) }
              }).catch(function(e) {
                console.log(e);
              });

           }
         }
        }
    };
    var data = JSON.stringify({ query:`{
       resourcesByOrangelightId(id: "` + component_id + `"){
         id,
         label,
         sourceMetadataIdentifier,
         url
       }
     }`
    })
    xhr.send(data);
  }

  renderReadingRoom(manifestURL) {
    var readingroom = document.getElementById("readingroom");
    if(readingroom){
      readingroom.innerHTML = "";
      readingroom.style.backgroundColor = '#ffffff';
      var viewerElement = this.constructViewerElement(manifestURL);
      document.getElementById("readingroom").appendChild(viewerElement);
    }
  }
}
