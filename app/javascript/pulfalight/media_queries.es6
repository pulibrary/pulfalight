export default class MediaQueries {
  handleMobileChange(mediaQueryObj) {
    // checks if it has hit the breakpoint specified when creating the query
    if (mediaQueryObj.matches) { 
      $('#toc').collapse('hide')
    }
  }

  // collapses the table of contents once the screen width is a mobile size
  setupTableCollapse() {
    // using medium breakpoint from app/assets/stylesheets/variables/breaks.scss
    const mediaQuery = window.matchMedia('(max-width: 768px)')
    mediaQuery.addListener(this.handleMobileChange)
    this.handleMobileChange(mediaQuery)
  }

  build() {
    this.setupTableCollapse()
  }
}
