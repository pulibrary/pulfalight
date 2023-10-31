// To see this message, add the following to the `<head>` section in your
// views/layouts/application.html.erb
//
//    <%= vite_client_tag %>
//    <%= vite_javascript_tag 'application' %>
console.log('Vite ⚡️ Rails')

/* eslint no-console:0 */
import "core-js/stable";
import "regenerator-runtime/runtime";
import PulfalightLoader from "@/pulfalight/pulfalight_loader.es6"

document.addEventListener('DOMContentLoaded', () => {
  // Load components
  const loader = new PulfalightLoader
  loader.run()
})
