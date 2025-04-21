<template>

  <transition name="slide">

  <div v-if="isVisible" :class="['request-cart']">

    <div class="panel">
      <table :class="['lux-data-table', 'fixed-header']">

        <caption>

          <lux-input-button
            v-on:click="toggleCartView($event)"
            width="26px"
            type="button"
            variation="text"
            class="denied-button"
            ref="closeCart"
            aria-labelledby="closeCart"
            >

            <div class="lux-icon">
              <svg
                xmlns="http://www.w3.org/2000/svg"
                width="1em"
                height="1em"
                viewBox="0 0 16 16"
                aria-labelledby="closeCart"
                role="img"
                fill="#6e757c"
                >
                <title id="closeCart" lang="en">close cart</title>
                <x-circle-icon></x-circle-icon>
              </svg>
            </div>
          </lux-input-button>

          <div class="caption-title">
            <span>Request Cart</span>
            <lux-icon-base width="30" height="30" icon-name="Cart">
              <lux-icon-cart></lux-icon-cart>
            </lux-icon-base>
          </div>
          <div class="caption-note">
            Add items from multiple pages and request them all at once.
          </div>
        </caption>

        <thead>
          <tr>
            <th width="275rem">Title</th>
            <th width="150rem">Call Number</th>
            <th width="150rem">Containers</th>
            <th class="action-header">&nbsp;</th>
          </tr>
        </thead>

        <tbody>
          <template v-for="(item, index) in requests" key="index"
            >
            <tr
              :id="'item-' + item.callnumber"
              class="lux-cartItem request"
              >
              <td width="275rem">{{ item.title }}</td>
              <td width="150rem">{{ item.callnumber }}</td>
              <td width="150rem">
                {{ item.containers }}
              </td>
              <td>
                <lux-input-button
                  @click="removeFromCart(item)"
                  type="button"
                  variation="outline"
                  >
                  Remove
                </lux-input-button>
              </td>
            </tr>

            <tr v-if="item.location && item.location.label" class="request__location">
              <td colspan="4">
                <geo-icon></geo-icon>
                This item can be viewed in person at <template v-if="item.location.url"><a
                  :href="item.location.url" target="_blank">{{ item.location.label.replace("Manuscript ", "")
                  }}</a></template><template v-else>{{ item.location.label.replace("Manuscript ", "") }}</template>.
                  These item(s) will be paged upon your arrival to the reading room.
              </td>
            </tr>

            <tr v-if="item.location && item.location.notes" class="request__location-notes">
              <td colspan="4">
                <lux-icon-base icon-name="Delivery">
                  <lux-icon-delivery></lux-icon-delivery>
                </lux-icon-base>
                {{ item.location.notes }}
              </td>
            </tr>
          </template>
        </tbody>
      </table>

    </div><!-- /.panel -->

    <div class="cart-actions">
      <div class="center">
        <form id="request-cart-form" method="post" :action="configuration.url"
                                     v-on:submit.prevent="clearForm">
          <div class="hidden">
            <template v-for="(request, requestIndex) in requests">
              <template v-for="(form_values, field_name) in request.formParams">
                <div v-if="Array.isArray(form_values)">
                  <template v-for="(value) in form_values">
                    <input :id="field_name" :name="field_name" type="hidden"
                                                                      :value="value"></input>
                  </template>
                </div>
                <input v-else :id="field_name" :name="field_name" type="hidden"
                                                           :value="form_values"></input>
              </template>
            </template>
          </div>

          <div id="request-notes-wrapper">
            <lux-input-text
              id="request-notes"
              label="Notes"
              name="Notes"
              :hide-label="true"
              placeholder="Notes to Special Collections Staff"
              width="expand"
              type="textarea"
              rows=2
              v-model:value="note"
            />
          </div>
          <lux-input-button type="submit" variation="solid" :disabled="requests.length == 0" block>
            {{ requestButtonText() }}
          </lux-input-button>
        </form>
      </div>
    </div>

    <form id="shadow-form" method="post" :action="configuration.url"
                           ref="shadowForm">
      <div class="hidden">
        <template v-for="(form_values, field_name) in globalFormParams">
          <input :id="field_name" :name="field_name" type="hidden"
                                                     :value="form_values"></input>
        </template>
        <template v-for="(request, requestIndex) in shadowRequests">
          <template v-for="(form_values, field_name) in request.formParams">
            <div v-if="Array.isArray(form_values)">
              <template v-for="(value) in form_values">
                <input :id="field_name" :name="field_name" type="hidden"
                                                           :value="value"></input>
              </template>
            </div>
            <input v-else :id="field_name" :name="field_name" type="hidden"
                                                              :value="form_values"></input>
          </template>
        </template>
        <input name="Notes" type="hidden" :value="note" />
      </div>
    </form>

  </div>
  </transition>
</template>

<script>
import { mapState, mapGetters } from "vuex"
import LuxIconCart from './RequestCartIcon.vue'
import GeoIcon from './GeoIcon.vue'
import TruckIcon from './TruckIcon.vue'
import XCircleIcon from './XCircleIcon.vue'
import RequestFormInput from './RequestFormInput.vue'
export default {
  name: "RequestCart",
  components: {
    'lux-icon-cart': LuxIconCart,
    'geo-icon': GeoIcon,
    'truck-icon': TruckIcon,
    'x-circle-icon': XCircleIcon,
    'request-form-input': RequestFormInput
  },
  data() {
    return {
      shadowRequests: [],
      note: ""
    }
  },
  props: {
    configuration: {
      type: Object,
      required: true,
      default: () => {}
    },
    globalFormParams: {
      type: Object,
      required: true,
      default: () => {}
    }
  },
  computed: {
    requests() {
      return this.$store.state.cart.items
    },
    isVisible: {
      get() {
        return this.$store.state.cart.isVisible
      },
      set() {
        this.$store.commit("TOGGLE_VISIBILITY")
      }
    }
  },
  watch: {
    isVisible(newIsVisible, oldIsVisible) {
      if(newIsVisible){
          this.$nextTick(()=>{
            this.$refs.closeCart.$el.focus()
          })
      }
    },
  },
  methods: {
    displayContainers(containers) {
      let displayString = containers.map(function(container) {
        let value = 'Unspecified'
        if (container.type) {
          value = container.type.charAt(0).toUpperCase() + container.type.slice(1) + " " + container.value
        }
        return value
      })
      return displayString.join(", ")
    },
    requestButtonText() {
      if (this.requests.length == 0) {
        return "No Items in Your Cart"
      }
      let text = "Request " + this.requests.length + " Item"
      if (this.requests.length > 1) {
        text = text + "s"
      }
      return text
    },
    removeFromCart(item) {
      this.$store.dispatch("removeItemFromCart", item)
    },
    toggleCartView(event) {
      this.$store.commit("TOGGLE_VISIBILITY")
    },
    clearForm() {
      this.shadowRequests = this.requests
      this.$store.commit("SET_CART", [])
      // ensure shadowform is re-rendered with items before submission
      this.$nextTick(() => {
        this.$refs.shadowForm.submit()
      })
    }
  }
}
</script>

<style lang="scss" scoped>
@import "lux-design-system/dist/style.scss";
#request-notes-wrapper {
  width: 100%;
  margin-left: 0.25rem;
  margin-right: -0.25rem;
  margin-bottom: 9px;
  max-height: 50px;
  overflow: hidden;
}
.lux-data-table {
  table-layout: fixed;
  width: 100%;
  border-collapse: collapse;
  border-spacing: 0;
  border-left: none;
  border-right: none;
  border-bottom: none;
  caption {
    margin-bottom: 24px;
    display: table-caption;
    text-align: left;
    font-size: 36px;
    font-size: 2vw;
    font-weight: 700;
    font-family: franklin-gothic-urw, Helvetica, Arial, sans-serif;
    line-height: 1;
    &:last-child {
      margin-bottom: 0;
    }
  }
  .caption-note {
    font-size: 16px;
    margin-bottom: 12px;
    font-weight: 350;
  }
  tbody {
    background-color: #fff;
    width: 100%;
    background-color: #fff;
    tr {
      display: table-row;
      vertical-align: inherit;
      background-color: #fff;
      color: #41464e;
      &:hover input,
      &:hover {
        background: #faf9f5;
      }
    }
  }
}
@media (max-width: 63.3em) {
  .lux-data-table caption {
    font-size: 1.266em;
  }
}
@media (min-width: 88.85em) {
  .lux-data-table caption {
    font-size: 1.777em;
  }
}


.lux-data-table {
    width: 100%;
    table-layout: fixed;
    border-collapse: collapse;
}

.lux-data-table tbody{
  display:block;
  width: 100%;
  overflow: auto;
  height: calc(100% - 162px);
}

.lux-data-table tr {
  display: table;
  width: 100%;
  table-layout: fixed;
}

.lux-data-table thead {
  vertical-align: middle;
  width: 100%;
}
.lux-data-table thead tr {
  display: table;
  background-color: #f5f5f5;
  color: #001123;
}
.lux-data-table th {
  line-height: 22px;

  font-weight: 600;
  font-family: franklin-gothic-urw, Helvetica, Arial, sans-serif;
  font-size: 12px;
  line-height: 1;
  text-align: left;
  text-transform: uppercase;
  color: #41464e;
  letter-spacing: 0.5px;
}
.lux-data-table td,
.lux-data-table th {
  border: none;
  border-top: 1px solid #dcdcdc;
  padding: 14px 24px;
  overflow: hidden;
}
.lux-data-table th button {
  padding: 0;
  font-weight: 600;
  font-family: franklin-gothic-urw, Helvetica, Arial, sans-serif;
  font-size: 12px;
  line-height: 1;
  text-align: left;
  text-transform: uppercase;
  color: #41464e;
  letter-spacing: 0.5px;
}
.lux-data-table td {
  color: #001123;
  font-weight: 400;
  font-family: franklin-gothic-urw, Helvetica, Arial, sans-serif;
  font-size: 16px;
  line-height: 1.2;
  text-align: left;
}
.lux-data-table td input {
  position: relative;
  width: auto;
  cursor: pointer;
}
.lux-data-table td input:checked,
.lux-data-table td input:focus,
.lux-data-table td input:hover {
  box-shadow: none;
  border: 0;
}
.lux-data-table td input:after,
.lux-data-table td input:before {
  position: absolute;
  content: "";
  display: inline-block;
}
.lux-data-table td input:before {
  height: 16px;
  width: 16px;
  background-color: #fff;
  border: 0;
  border-radius: 3px;
  box-shadow: inset 0 1px 0 0 rgba(0, 17, 35, 0.07), 0 0 0 1px #cccfd3;
  left: 0;
  top: 4px;
}
.lux-data-table td input:not([disabled]):hover:before {
  box-shadow: 0 1px 5px 0 rgba(0, 17, 35, 0.07), 0 0 0 1px #99a0a7;
}
.lux-data-table td input:checked:before {
  transition: box-shadow 0.2s ease;
  background-color: #2c6eaf;
  box-shadow: inset 0 0 0 1px #2c6eaf, 0 0 0 1px #2c6eaf;
  outline: 0;
}
.lux-data-table td input:after {
  height: 5px;
  width: 10px;
  border-left: 2px solid #fff;
  border-bottom: 2px solid #fff;
  transform: rotate(-45deg);
  left: 3px;
  top: 7px;
}
.lux-data-table td input[type="checkbox"]:after {
  content: none;
}
.lux-data-table td input[type="checkbox"]:checked:after {
  content: "";
}
.lux-data-table td input[type="checkbox"]:focus:before {
  transition: box-shadow 0.08s ease;
  box-shadow: inset 0 0 0 1px #2c6eaf, 0 0 0 1px #2c6eaf;
}
.lux-data-table .lux-data-table-currency {
  text-align: right;
}
.lux-data-table .lux-data-table-currency > span:before {
  content: "$";
}
.lux-data-table .lux-data-table-number {
  text-align: right;
}
.lux-data-table .lux-data-table-left {
  text-align: left;
}
.lux-data-table .lux-data-table-center {
  text-align: center;
}
.lux-data-table .lux-data-table-right {
  text-align: right;
}

/* Copied from upstream */
.slide-enter-active,
.slide-leave-active {
  transform: translateX(0%);
  transition: 0.3s ease-out;
}
.slide-enter,
.slide-leave-to {
  transform: translateX(100%);
  transition: 0.3s ease-out;
}
/* Component Styling */
.request-cart {
  /* Custom */
  position: fixed;
  z-index: 2020;
  display: block;
  top: 20%;
  height: 80%;
  right: 0;
  background-color: #ffffff;
  border: 1px solid #8f8f8f;
  width: 40%;
  .denied-button {
    font-size: 1.5rem;
    padding: 6px;
    display: inline-block;
    text-align: left;
    margin: 0px;
    padding: 0px;
    color: #6e757c;
  }
  .caption-title {
    margin-top: 1rem;
    margin-bottom: 1rem;
  }
}
.lux-data-table {
  width: 100%;
  margin-top: 0px;
  display: block;
  height: 100%;
  caption {
    caption-side: inherit;
    margin-bottom: 0px;
    padding-top: 0px;
    padding-bottom: 0px;
  }
}
.panel {
  @include reset;
  @include stack-space($space-base);
  padding-left: 0.8rem;
  padding-right: 0.8rem;
  padding-top: 0.8rem;
  font-family: $font-family-text;
  line-height: $line-height-base;
  background: $color-white;
  box-shadow: $box-shadow-small;
  color: $color-rich-black;
  overflow: hidden;
  height: calc(100% - 120px);
  margin-bottom: 0px;
}
.cart-actions {
  background: $color-rich-black;
  color: $color-white;
  height: 120px;
  width: 100%;
}
.center {
  margin: auto;
  width: 80%;
  text-align: center;
  padding: 15px 0;
}
.top-left {
  position: absolute;
  left: -10px;
  top: 0px;
}
table {
  margin-top: 2em;
}

/*
 * Custom Styling
 */
.request-cart {

  @media screen and (max-width: 1024px) {
    width: 100%;
    height: 100%;
    top: 0%;
  }

  @media screen and (max-width: 640px) {
    th {
      display: none;

      &.action-header {
        display: table-cell;
        min-width: 100%;
        width:100%;
      }
    }

    th:first-child {
      display: table-cell;
    }
  }
}

.request {
  @media screen and (max-width: 640px) {
    td {
      display: none;
    }

    td:first-child, td:last-child {
      display: table-cell;
      min-width: 100%;
    }
  }

  &__location, &__location-notes {
  td {
      border-top-width: 0px;
      border-bottom-width: 0px;
      color: #707070;
      font-style: italic;
    }
  }
}

</style>
