import {createApp} from "vue"
import lux from "lux-design-system"
import "lux-design-system/dist/style.css"
import Vuex from "vuex"
import { store } from '@/store/index.es6'
import RequestCart from '@/components/RequestCart.vue'
import AddToCartButton from '@/components/AddToCartButton.vue'
import AddToCartIcon from '@/components/AddToCartIcon.vue'
import CartViewToggle from '@/components/CartViewToggle.vue'
import TocBuilder from "@/pulfalight/toc.es6"
import LibCalHours from "@/pulfalight/lib_cal_hours.es6"
import ChildTable from "@/components/ChildTable.vue"
import PulfaDataTable from "@/components/PulfaDataTable.vue"
import FiggyViewer from "@/components/FiggyViewer.vue"
import MediaQueries from "@/pulfalight/media_queries.es6"


export default class {
  run() {
    this.setup_toc()
    this.setup_vue()
    this.setup_lib_cal_hours()
    this.setup_form_modal()
    this.setup_media_queries()
  }

  setup_lib_cal_hours() {
    const elements = document.getElementsByClassName("hours")
    for (var i = 0; i < elements.length; i++) {
      new  LibCalHours(elements[i]).insert_hours()
    }
  }

  setup_toc() {
    const toc = new TocBuilder('#toc')
    toc.build()
  }

  setup_media_queries() {
    const mediaQueries = new MediaQueries()
    mediaQueries.build()
  }

  setup_vue() {
    const app = createApp({});
    const createMyApp = () => createApp(app);

    const elements = document.getElementsByClassName('lux')
    for (let i = 0; i < elements.length; i++) {
      createMyApp()
        .use(lux)
        .use(store)
        .component('child-table', ChildTable)
        .component('figgy-viewer', FiggyViewer)
        .component('request-cart', RequestCart)
        .component('cart-view-toggle', CartViewToggle)
        .component('add-to-cart-button', AddToCartButton)
        .component('add-to-cart-icon', AddToCartIcon)
        .mount(elements[i])
    }
  }

  // Set up Suggest a Correction/Ask a Question modals. Rails UJS submits as a remote form, and
  // ContactController#suggest/#question returns the form partial in response to the
  // request.
  setup_form_modal() {
    ["#correctionModal", "#questionModal", "#harmfulLanguageModal", "#generalFeedback"].forEach((selector) => {
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
