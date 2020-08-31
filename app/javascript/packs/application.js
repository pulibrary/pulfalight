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
import Vuex from "vuex"

import system from 'lux-design-system'
import "lux-design-system/dist/system/system.css"
import "lux-design-system/dist/system/tokens/tokens.scss"

Vue.use(system)

import store from '../store'
import RequestCart from '../components/RequestCart.vue'
import AddToCartButton from '../components/AddToCartButton.vue'
import CartViewToggle from '../components/CartViewToggle.vue'

function ComponentBuilder() {}
ComponentBuilder.build = function(className) {
  var elements = document.getElementsByClassName(className)

  for (var i = 0; i < elements.length; i++) {
    new Vue({
      el: elements[i],
      store,
      components: {
        'request-cart': RequestCart,
        'add-to-cart-button': AddToCartButton,
        'cart-view-toggle': CartViewToggle
      }
    })
  }
}

function RequestCartFactory() {}
RequestCartFactory.build = function() {
  ComponentBuilder.build('request-cart-block')
  ComponentBuilder.build('add-to-cart-block')
  ComponentBuilder.build('cart-view-toggle-block')
}

document.addEventListener("DOMContentLoaded", () => {

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
