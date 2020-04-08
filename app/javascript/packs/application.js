/* eslint no-console:0 */
// This file is automatically compiled by Webpack, along with any other files
// present in this directory. You're encouraged to place your actual application logic in
// a relevant structure within app/javascript and only use these pack files to reference
// that code so it'll be compiled.
//
// To reference this file, add <%= javascript_pack_tag 'application' %> to the appropriate
// layout file, like app/views/layouts/application.html.erb


// Uncomment to copy all static images under ../images to the output folder and reference
// them with the image_pack_tag helper in views (e.g <%= image_pack_tag 'rails.png' %>)
// or the `imagePath` JavaScript helper below.
//
// const images = require.context('../images', true)
// const imagePath = (name) => images(name, true)

import "core-js/stable";
import "regenerator-runtime/runtime";

import Vue from 'vue/dist/vue.esm'
import system from 'lux-design-system'
import "lux-design-system/dist/system/system.css"
import "lux-design-system/dist/system/tokens/tokens.scss"
import Mmenu from 'mmenu-js'
import "mmenu-js/dist/mmenu.css"
import "mmenu-js/dist/mmenu.polyfills.js"

Vue.use(system)

document.addEventListener("DOMContentLoaded", () => {
  const menu = document.querySelector('#menu')
  if(menu !== null) {
    new Mmenu( document.querySelector( '#menu' ), {
      "slidingSubmenus": false,
      "counters": true,
      "offCanvas": false,
      "extensions": [
        "multiline"
      ],
      "navbar": {
        "add": false
      },
      "sidebar": {
        "collapsed": "(min-width: 550px)",
        "expanded": "(min-width: 700px)"
      }
    });
  }

  var elements = document.getElementsByClassName("lux")
  for (var i = 0; i < elements.length; i++) {
    new Vue({
      el: elements[i]
    })
  }

})
