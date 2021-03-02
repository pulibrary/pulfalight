import Vue from 'vue/dist/vue.esm'
import Vuex from "vuex"
import system from 'lux-design-system'
import "lux-design-system/dist/system/system.css"
import "lux-design-system/dist/system/tokens/tokens.scss"
import store from '../store'
import RequestCart from '../components/RequestCart'
import AddToCartButton from '../components/AddToCartButton'
import AddToCartIcon from '../components/AddToCartIcon'
import CartViewToggle from '../components/CartViewToggle'
import TocBuilder from "../pulfalight/toc.es6"
import LibCalHours from "../pulfalight/lib_cal_hours.es6"
import QueryFiggy from "../pulfalight/query_figgy.es6"
import ChildTable from "../components/ChildTable"

export default class {
  run() {
    this.setup_toc()
    this.setup_vue()
    this.setup_lib_cal_hours()
    this.setup_range_limit()
    this.setup_form_modal()
    this.query_figgy()
  }

  query_figgy(){
    const query = new QueryFiggy()
    const component_id = query.component_id()
    query.checkFiggy(component_id)
  }

  load_child_table() {
    const childTable = new ChildTable($("#child-table"))
    childTable.initialize()
  }

  setup_lib_cal_hours() {
    const elements = document.getElementsByClassName("hours")
    for (var i = 0; i < elements.length; i++) {
      new  LibCalHours(elements[i]).insert_hours()
    }
  }

  setup_range_limit() {
    // Initialize the range limit interface
    $('.blacklight-date_range_sim').data('plot-config', {
          selection: { color: '#C0FF83' },
          colors: ['#ffffff'],
          series: { lines: { fillColor: 'rgba(255,255,255, 0.5)' }},
          grid: { color: '#aaaaaa', tickColor: '#aaaaaa', borderWidth: 0 }
    });
  }

  setup_toc() {
    const toc = new TocBuilder('#toc')
    toc.build()
  }

  setup_vue() {
    Vue.use(system)
    var elements = document.getElementsByClassName("lux")
    for (var i = 0; i < elements.length; i++) {
      new Vue({
        el: elements[i],
        store,
        components: {
          'request-cart': RequestCart,
          'add-to-cart-button': AddToCartButton,
          'add-to-cart-icon': AddToCartIcon,
          'cart-view-toggle': CartViewToggle,
          'child-table': ChildTable
        }
      })
    }
  }

  // Set up Suggest a Correction/Ask a Question modals. Rails UJS submits as a remote form, and
  // ContactController#suggest/#question returns the form partial in response to the
  // request.
  setup_form_modal() {
    ["#correctionModal", "#questionModal"].forEach((selector) => {
      $(`${selector}`).on("show.bs.modal", function() {
        $(`${selector} form`).show()
        $(`${selector} .alert`).hide()
      })
      $(`${selector}`).on("ajax:error", function(event) {
        $(`${selector} .form-wrapper`).html(event.detail[0].body)
      }).on("ajax:success", function(event) {
        $(`${selector} .form-wrapper`).html(event.detail[0].body)
        $(`${selector} .form-wrapper form`).hide()
        $(`${selector} .form-wrapper .is-valid`).removeClass("is-valid")
      })
    })
  }
}
