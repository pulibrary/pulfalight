/* eslint no-console:0 */
import "core-js/stable";
import "regenerator-runtime/runtime";

import Vue from 'vue/dist/vue.esm'
import system from 'lux-design-system'
import "lux-design-system/dist/system/system.css"
import "lux-design-system/dist/system/tokens/tokens.scss"
import TocBuilder from "../packs/toc.es6"

Vue.use(system)

<<<<<<< HEAD
document.addEventListener('turbolinks:load', () => {
=======
import RequestCart from '../RequestCart.vue'

function ComponentBuilder() {}
ComponentBuilder.build = function(className, componentClass) {
  console.log(className)
  console.log(componentClass)

  var elements = document.getElementsByClassName(className)

  for (var i = 0; i < elements.length; i++) {
    console.log(elements[i])

    new Vue({
      el: elements[i],
      components: {
        'request-cart': RequestCart
      }
    })
  }
}

function RequestCartFactory() {}
RequestCartFactory.build = function() {
  ComponentBuilder.build('request-cart-block', RequestCart)
}

document.addEventListener("DOMContentLoaded", () => {
>>>>>>> Porting an original Aeon request support implementation from an older branch
  var elements = document.getElementsByClassName("lux")
  for (var i = 0; i < elements.length; i++) {
    new Vue({
      el: elements[i]
    })
  }

  RequestCartFactory.build()

  // Initialize the range limit interface
  $('.blacklight-date_range_sim').data('plot-config', {
        selection: { color: '#C0FF83' },
        colors: ['#ffffff'],
        series: { lines: { fillColor: 'rgba(255,255,255, 0.5)' }},
        grid: { color: '#aaaaaa', tickColor: '#aaaaaa', borderWidth: 0 }
  });
})

/**
 * Table of Contents initialization
 */

// Setup table of contents on initial page load
document.addEventListener('DOMContentLoaded', () => {
  const toc = new TocBuilder('#toc')
  toc.build()
  // Set initial toc build flag
  window.buildToc = true
})

// The before-visit event only fires when a Turbolinks-enabled link is clicked
document.addEventListener('turbolinks:before-visit', () => {
  // We do NOT want to rebuild the table of contents when a link is clicked.
  // Provides a better user experience and reduces the number of AJAX requests.
  window.buildToc = false
})

// Add listener for event that fires after turbolinks loads page
// We DO want to rebuild the table of contents if navigating via history API.
// Otherwise, the nodes on the tree are stale.
document.addEventListener('turbolinks:load', () => {
  if(window.buildToc) {
    // Remove existing tree
    $('#toc').jstree('destroy').empty()
    // Build new tree
    const toc = new TocBuilder('#toc')
    toc.build()
  } else {
    // Reset the toc build flag
    window.buildToc = true
  }
})
