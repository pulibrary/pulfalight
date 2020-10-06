/* eslint no-console:0 */
import "core-js/stable";
import "regenerator-runtime/runtime";
import PulfalightLoader from "../pulfalight/pulfalight_loader.es6"
import TocLoader from "../pulfalight/toc_loader.es6"


// Setup Table of Contents
const toc_loader = new TocLoader
toc_loader.run()

document.addEventListener('turbolinks:load', () => {
  // Setup all other components
  const loader = new PulfalightLoader
  loader.run()
})
