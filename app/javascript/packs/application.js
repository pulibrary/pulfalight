/* eslint no-console:0 */
import "core-js/stable";
import "regenerator-runtime/runtime";
import PulfalightLoader from "../pulfalight/pulfalight_loader.es6"

document.addEventListener('DOMContentLoaded', () => {
  // Load components
  const loader = new PulfalightLoader
  loader.run()
})
