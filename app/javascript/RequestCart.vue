<template>
  <div :class="['request-cart']">
    <div v-if="requests.length" class="panel">

      <form method="post" :action="configuration.url">
        <table :class="['lux-data-table']">
          <caption>
            Request Cart
            <lux-icon-base width="30" height="30" icon-name="Cart">
              <lux-icon-cart></lux-icon-cart>
            </lux-icon-base>
          </caption>

          <thead>
            <tr>
              <th>Title</th>
              <th>Call Number</th>
              <th colspan="2">Containers</th>
            </tr>
          </thead>

          <tbody>
            <template v-for="(item, index) in requests">

            <tr
              :key="item.callnumber"
              :id="item.callnumber"
              class="lux-cartItem request"
              >
              <td>{{ item.title }}</td>
              <td>{{ item.callnumber }}</td>
              <td>
                {{ displayContainers(item.containers) }}
                <br />
                <em v-if="item.subcontainers.length">
                  [{{ displayContainers(item.subcontainers) }}]
                </em>
              </td>
              <td>
                <input-button
                  @button-clicked="removeFromCart(item)"
                  type="button"
                  variation="outline"
                  >
                  Remove
                </input-button>
              </td>
            </tr>

            <tr v-if="item.location" class="request__location">
              <td colspan="4">
                <geo-icon></geo-icon>
                View this item at the <a :href="item.location.url">Mudd Library Reading Room</a>
              </td>
            </tr>

            <tr v-if="item.location && item.location.notes" class="request__location-notes">
              <td colspan="4">
                <truck-icon></truck-icon>
                {{ item.location.notes }}
              </td>
            </tr>

            </template>
          </tbody>
        </table>

        <div class="hidden">
          <template v-for="(param, index) in params">

          </template>
        </div>

        <div class="cart-actions">
          <div class="center">
            <input-button type="submit" variation="solid" block>
              {{ requestButtonText() }}
            </input-button>
          </div>
        </div>
      </form>
    </div>

    <div v-else class="panel">
      <heading level="h3">Your cart is currently empty.</heading>
    </div>
  </div>
</template>

<script>
import LuxIconCart from './RequestCartIcon.vue'
import GeoIcon from './GeoIcon.vue'
import TruckIcon from './TrackIcon.vue'

export default {
  name: "RequestCart",
  components: {
    'lux-icon-cart': LuxIconCart,
    'geo-icon': GeoIcon,
    'truck-icon': TruckIcon
  },
  props: {
    configuration: {
      type: Object,
      required: true,
      default: () => {}
    },

    requests: {
      type: Array,
      required: false,
      default: () => { [] }
    },

    formParams: {
      type: Array,
      required: false,
      default: () => { [] }
    }
  },
  methods: {
    displayContainers(containers) {
      let displayString = containers.map(function(container) {
        return (
          container.type.charAt(0).toUpperCase() + container.type.slice(1) + " " + container.value
        )
      })
      return displayString.join(", ")
    },
    requestButtonText() {
      let text = "Request " + this.requests.length + " Item"

      if (this.requests.length > 1) {
        text = text + "s"
      }
      return text
    }
  }
}
</script>

<style lang="scss" scoped>

.lux-data-table {
  border-collapse: collapse;
  border-spacing: 0;
  border-left: none;
  border-right: none;
  border-bottom: none;
}

.lux-data-table caption {
  margin-bottom: 24px;
  display: table-caption;
  text-align: left;
  font-size: 36px;
  font-size: 2vw;
  font-weight: 700;
  font-family: franklin-gothic-urw, Helvetica, Arial, sans-serif;
  line-height: 1;
}
.lux-data-table caption:last-child {
  margin-bottom: 0;
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
.lux-data-table thead {
  display: table-header-group;
  vertical-align: middle;
}
.lux-data-table thead tr {
  background-color: #f5f5f5;
  color: #001123;
}
.lux-data-table th {
  line-height: 22px;
  padding: 20px;
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
.lux-data-table tbody tr {
  display: table-row;
  vertical-align: inherit;
  background-color: #fff;
  color: #41464e;
}
.lux-data-table tbody tr:hover input,
.lux-data-table tbody tr:hover {
  background: #faf9f5;
}
.lux-data-table tbody {
  background-color: #fff;
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
@mixin reset {
  box-sizing: border-box;
  padding: 0;
  margin: 0;
}

/* Copied from upstream */
@mixin stack-space($value) {
  margin-bottom: $value;
  &:last-child {
    margin-bottom: 0;
  }
}

/* Copied from upstream */
$font-family-text: "franklin-gothic-urw", Helvetica, Arial, sans-serif;
$line-height-base: 1.6;
$color-white: rgb(255, 255, 255);
$box-shadow-small: 0 0 0 1px rgba(92, 106, 196, 0.1);
$color-rich-black: rgb(0, 17, 35);
$space-base: 24px;

/* Component Styling */

.request-cart {
  margin-left: 0.8rem;
  margin-right: 0.8rem;
}

.lux-data-table {
  width: 100%;
}

.lux-data-table caption {
  caption-side: inherit;
}

.panel-wrap {
  position: fixed;
  top: 0px;
  bottom: 0;
  right: 0;
  width: 38em;
  transform: translateX(0%);
  z-index: 1000; /* Stay on top */
}

.panel {
  @include reset;
  @include stack-space($space-base);
  font-family: $font-family-text;
  line-height: $line-height-base;
  background: $color-white;
  box-shadow: $box-shadow-small;
  color: $color-rich-black;
  position: absolute;
  top: 0;
  bottom: 0;
  left: 0;
  right: 0;
  overflow: auto;
  padding: 1em;
}

.cart-actions {
  position: absolute;
  left: 0px;
  bottom: 0px;
  background: $color-rich-black;
  color: $color-white;
  height: 80px;
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

/*
 * Custom Styling
 */
.request {
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
