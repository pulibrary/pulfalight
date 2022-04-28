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

  uppercaseChar(str,underscorePosition) {
    let component_id_upperCase = ''
    for (let i = 0; i < underscorePosition; i++) {
      component_id_upperCase += str.charAt(i).toUpperCase();
    }
    return component_id_upperCase;
  }

  component_id() {
    return document.querySelector("*[data-component-id]").getAttribute('data-component-id')
  }

  async checkFiggy(component_id) {
    var url = "https://figgy.princeton.edu/graphql";
    var data = JSON.stringify({ query:`{
       resourcesByOrangelightId(id: "` + component_id + `"){
         id,
         embed {
          type,
          content,
          status
        }
       }
     }`
    })

    return fetch(url,
      {
        method: "POST",
        credentials: 'include',
        body: data,
        headers: {
          'Content-Type': 'application/json',
        }
      }
    )
    .then((response) => response.json())
    .then((response) => response.data.resourcesByOrangelightId[0])
    .then((result) => this.embedContent(result))
  }

  embedContent(json) {
    if(json.embed.content === null && json.embed.status === "unauthenticated") {
      this.addLoginLink()
    } else if(json.embed.status === "authorized") {
      if(this.readingRoom){
        if(json.embed.type === "html") {
          this.readingRoom.innerHTML = json.embed.content
          this.readingRoom.firstElementChild.classList.add("intrinsic-container", "intrinsic-container-16x9", "uv__overlay")
        } else if(json.embed.type === "link") {
          this.readingRoom.innerHTML = `<a href="${json.embed.content}" class="lux-link button solid large">${this.linkLabel(json.embed.content)}</a>`
        }
      }
    }
  }

  get readingRoom() {
    return document.getElementById("readingroom");
  }

  linkLabel(figgyLink) {
    let daoLabel = this.readingRoom.dataset.daoLabel
    if(daoLabel === '' || figgyLink != this.daoLink) {
      return "Download Content"
    }
    return daoLabel
  }

  get daoLink() {
    return this.readingRoom.dataset.daoLink
  }
}
