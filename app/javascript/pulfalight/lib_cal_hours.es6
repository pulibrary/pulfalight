export default class LibCalHours {
  constructor(element) {
    this.element = $(element)
  }

 get url() {
   const id = this.element.data("id")
   return `/hours?id=${id}`
 }

 async insert_hours() {
  return $.getJSON(this.url).promise()
    .then(this.process_response.bind(this))
 }

 process_response(response) {
   const rendered_hours = response["hours"]
   this.element.text(rendered_hours)
 }
}
