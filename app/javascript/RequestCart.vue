<template>
  <div :class="['request-cart']">
      <form method="post" :action="configuration.url">

        <table :class="['lux-data-table']">
          <caption>
            Request Cart
          </caption>

          <thead>
            <tr>
              <th>Title</th>
              <th>Call Number</th>
              <th colspan="2">Containers</th>
            </tr>
          </thead>

          <tbody>
            <tr
              v-for="(item, index) in requests"
              :id="item.callnumber"
              :key="item.callnumber"
              class="lux-cartItem"
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
          </tbody>
        </table>
      </form>

  </div>
</template>

<script>
export default {
  name: "RequestCart",
  props: {
    configuration: {
      type: Object,
      required: true,
      default: () => {}
    },
    requests: {
      type: Array,
      required: true,
      default: []
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
    }
  }
}
</script>

<style lang="scss" scoped>

.panel-wrap {
  position: fixed;
  top: 0px;
  bottom: 0;
  right: 0;
  width: 38em;
  transform: translateX(0%);
  z-index: 1000; /* Stay on top */
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
</style>
