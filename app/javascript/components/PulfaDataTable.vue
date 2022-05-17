<template>
  <table border="1px" :class="['lux-data-table']">
    <caption>
      {{
        caption
      }}
    </caption>
    <thead>
      <tr>
        <th v-for="(col, index) in parsedColumns" scope="col" nowrap>
          <input-button
            v-if="col.sortable"
            type="button"
            v-on:button-clicked="sortTable(col)"
            variation="text"
          >
            <lux-icon-base
              v-if="col.sortable"
              width="16"
              height="16"
              :icon-name="iconLabel(col)"
            >
              <lux-icon-ascending v-if="col.ascending"></lux-icon-ascending>
              <lux-icon-descending v-if="col.ascending === false"></lux-icon-descending>
              <lux-icon-unsorted v-if="col.ascending === null"></lux-icon-unsorted>
            </lux-icon-base>
            {{ displayName(col) }}</input-button
          >
          <span v-else>{{ displayName(col) }}</span>
        </th>
      </tr>
    </thead>
    <tbody>
      <tr class="row" v-for="(lineItem, index) in rows">
        <td
          v-for="(col, index) in parsedColumns"
          :class="['lux-data-table-left'
            /* { 'lux-data-table-left': isLeft(col.align) },
            { 'lux-data-table-center': isCenter(col.align) },
            { 'lux-data-table-right': isRight(col.align) },
            { 'lux-data-table-number': isNum(col.datatype) },
            { 'lux-data-table-currency': isCurrency(col.datatype) }, */
          ]"
        >
          <div v-if="col.checkbox">
            <add-to-cart-button
              v-if="lineItem.requestable.value"
              :id="'add-to-cart-button_'+lineItem.id.value"
              type="checkbox"
              :aria-label="getAriaLabel(lineItem)"
              :name="col.name"
              :value="lineItem[col.name].value"
              class="add-to-cart-block"
              :title="lineItem.title.value"
              :callnumber="lineItem.id.value"
              :date="lineItem.date.value"
              :containers="lineItem.container.value"
              :form-params="lineItem.form_params"
              >
              <lux-icon-base :icon-name="'add-to-cart-icon_'+lineItem.id.value" width="20" height="20">
                  <add-to-cart-icon></add-to-cart-icon>
              </lux-icon-base>
              Request this box
            </add-to-cart-button>
          </div>

          <span v-else>
            <hyperlink v-if="lineItem[col.name].link" :href="lineItem[col.name].link">
              {{ lineItem[col.name].value }}
            </hyperlink>
            <span v-else>
              {{ lineItem[col.name].value }}
            </span>
          </span>
        </td>
      </tr>
    </tbody>
    <tfoot v-if="summaryLabel">
      <tr>
        <th scope="row">{{ summaryLabel }}</th>
        <td
          v-for="(col, index) in footerColumns"
          :class="[
            { 'lux-data-table-left': isLeft(col.align) },
            { 'lux-data-table-center': isCenter(col.align) },
            { 'lux-data-table-right': isRight(col.align) },
            { 'lux-data-table-number': isNum(col.datatype) },
            { 'lux-data-table-currency': isCurrency(col.datatype) },
          ]"
        >
          <span>
            {{ col.summary_value }}
          </span>
        </td>
      </tr>
    </tfoot>
  </table>
</template>

<script>
import system from 'lux-design-system'
import AddToCartButton from './AddToCartButton.vue'
import AddToCartIcon from './AddToCartIcon.vue'
export default {
  name: "PulfaDataTable",
  components: {
    'add-to-cart-button': AddToCartButton,
    'add-to-cart-icon': AddToCartIcon
  },
  data() {
    return {
      rows: this.jsonData,
      parsedColumns: [],
    }
  },
  props: {
    /**
     * caption provides context for the data that is helpful to users, particularly those who use screenreaders.
     * `e.g. [name, title, age]`
     */
    caption: {
      required: true,
      type: String,
    },
    /**
     * summaryLabel provides context to the data values in tfoot element cells.
     */
    summaryLabel: {
      required: false,
      type: String,
    },
    /**
     * columns define the columns and order for which the data should be displayed.
     * Columns entries can be simple strings, or they may be more complicated objects
     * that can define `name`, `display_name`,`align`, `sortable`, and `checkbox` properties.
     * Sorting on `numeric` or `currency` values requires a column to have
     * a `datatype='number'` or `datatype='currency'` property.
     * Sorting on `date` values requires a column to have
     * a `datatype='date'` property.
     * Use `checkbox=true` to create a checkbox whose value is the value for that
     * column value for the row in the table.
     * `e.g. ['name', 'email', 'age']`
     */
    columns: {
      required: true,
      type: Array,
    },
    /**
     * jsonData is supplied via Array with an object representing each row.
     * Applying links to data cell content can be achieved by supplying an object
     * that contains a `value` and `link` property. Date sorting uses the JavaScript
     * `datestring` parameter. Shorthand dates are supported in most browsers, but can be implementation-specific.
     * (e.g., `{ value: 'content', link: 'https://url.com'}`)
     * See above example for exact structure.
     */
    jsonData: {
      required: true,
      type: Array,
    },
  },
  created: function() {
    // Normalize the column data by converting any simple string field
    // names into objects with a name property
    let pCols = this.columns.map(col => {
      if (!this.isObject(col)) {
        return { name: col.toLowerCase(), ascending: null }
      } else {
        col.name = col.name.toLowerCase()
        if (col.sortable && typeof col.ascending === "undefined") {
          col.ascending = null
        }
        return col
      }
    })
    this.parsedColumns = pCols

    // Normalize the row data by converting any simple values into
    // objects with the link properties
    let rowNum = this.jsonData.length
    for (let i = 0; i < rowNum; i++) {
      // console.log(this.jsonData[i].name)
      for (var key in this.jsonData[i]) {
        if (this.jsonData[i].hasOwnProperty(key)) {
          if (!this.isObject(this.jsonData[i][key])) {
            this.jsonData[i][key] = { value: this.jsonData[i][key], link: null }
          }
        }
      }
    }
    this.rows = this.jsonData
  },
  computed: {
    footerColumns() {
      let fCols = this.columns
      fCols.shift()
      return fCols
    },
  },
  methods: {
    getAriaLabel(lineItems) {
      let lines = []
      for (const [key, item] of Object.entries(lineItems)) {
        lines.push(`${key}: ${item.value}`)
      }
      return lines.join(", ")
    },
    iconLabel(col) {
      if (col.ascending === true) {
        return "ascending_" + col.name
      } else if (col.ascending === false) {
        return "descending_" + col.name
      } else if (col.ascending === null) {
        return "unsorted_" + col.name
      }
    },
    displayName(col) {
      if (col.hasOwnProperty("display_name")) {
        return col.display_name
      } else {
        return col.name
      }
    },
    sortTable(col) {
      if (!col.ascending) {
        if (col.datatype === "number" || col.datatype === "currency") {
          this.rows.sort((a, b) => a[col.name].value - b[col.name].value)
        } else if (col.datatype === "date") {
          this.rows.sort((a, b) => new Date(a[col.name].value) - new Date(b[col.name].value))
        } else {
          this.rows.sort(function(a, b) {
            var textA = a[col.name.toLowerCase()].value.toString().toLowerCase()
            var textB = b[col.name.toLowerCase()].value.toString().toLowerCase()
            return textA < textB ? -1 : textA > textB ? 1 : 0
          })
        }
      } else {
        if (col.datatype === "number" || col.datatype === "currency") {
          this.rows.sort((a, b) => b[col.name].value - a[col.name].value)
        } else if (col.datatype === "date") {
          this.rows.sort((a, b) => new Date(b[col.name].value) - new Date(a[col.name].value))
        } else {
          this.rows.sort(function(a, b) {
            var textA = a[col.name.toLowerCase()].value.toString().toLowerCase()
            var textB = b[col.name.toLowerCase()].value.toString().toLowerCase()
            return textA < textB ? 1 : textA > textB ? -1 : 0
          })
        }
      }
      col.ascending = !col.ascending

      // reset other columns ascending prop to null (aka, "unsorted")
      this.parsedColumns = this.parsedColumns.map(function(column) {
        if (col.name != column.name) {
          column.ascending = null
        }
        return column
      })
    },
    isObject(value) {
      return value && typeof value === "object" && value.constructor === Object
    },
    isCurrency(value) {
      return value === "currency" ? true : false
    },
    isNum(value) {
      return value === "number" ? true : false
    },
    isLeft(value) {
      return value === "left" ? true : false
    },
    isCenter(value) {
      return value === "center" ? true : false
    },
    isRight(value) {
      return value === "right" ? true : false
    },
  },
}
</script>

<style lang="scss">
@import "lux-design-system/dist/system/tokens/tokens.scss";
@import "lux-design-system/dist/system/system.utils.scss";
.lux-data-table {
  border-collapse: collapse;
  border-spacing: 0;
  border-left: none;
  border-right: none;
  border-bottom: none;

  caption {
    @include stack-space($space-base);
    display: table-caption;
    text-align: left;
    @include responsive-font(
      2vw,
      $font-size-x-large-min,
      $font-size-x-large-max,
      $font-size-x-large
    );
    font-weight: $font-weight-bold;
    font-family: $font-family-text;
    line-height: $line-height-heading;
  }

  thead {
    display: table-header-group;
    vertical-align: middle;
  }

  thead tr {
    background-color: $color-grayscale-lighter;
    color: $color-rich-black;
  }

  th {
    line-height: 22px;
    padding: 20px;
    font-weight: $font-weight-semi-bold;
    font-family: $font-family-text;
    font-size: $font-size-x-small;
    line-height: $line-height-heading;
    text-align: left;
    text-transform: uppercase;
    color: $color-grayscale-darker;
    letter-spacing: 0.5px;
  }

  th,
  td {
    border-bottom: none;
    border-left: none;
    border-right: none;
    border-top: 1px solid darken($color-grayscale-lighter, 10%);
    @include inset-space($space-base);
    overflow: hidden;
  }

  th button {
    padding: 0px;
    font-weight: $font-weight-semi-bold;
    font-family: $font-family-text;
    font-size: $font-size-x-small;
    line-height: $line-height-heading;
    text-align: left;
    text-transform: uppercase;
    color: $color-grayscale-darker;
    letter-spacing: 0.5px;
    display: flex;
    align-items: center;
    margin: 0;

    ::v-deep .lux-icon {
      display: initial;
    }
  }

  tbody tr {
    display: table-row;
    vertical-align: inherit;
    background-color: $color-white;
    color: $color-grayscale-darker;

    &:hover {
      background: $color-grayscale-warm-lighter;

      input {
        background: $color-grayscale-warm-lighter;
      }
    }
  }

  tbody {
    background-color: #fff;
  }

  td {
    color: $color-rich-black;
    font-weight: $font-weight-regular;
    font-family: $font-family-text;
    font-size: $font-size-base;
    line-height: 1.2;
    text-align: left;

    input {
      position: relative;
      width: auto;
      cursor: pointer;

      &:hover,
      &:focus,
      &:checked {
        box-shadow: none;
        border: 0;
      }
    }

    input::before,
    input::after {
      position: absolute;
      content: "";

      /*Needed for the line-height to take effect*/
      display: inline-block;
    }

    /*Outer box of the fake checkbox*/
    input::before {
      height: 16px;
      width: 16px;
      background-color: $color-white;
      border: 0;
      border-radius: $border-radius-default;
      box-shadow: inset 0 1px 0 0 rgba($color-rich-black, 0.07),
        0 0 0 1px tint($color-rich-black, 80%);
    }

    /* On mouse-over, add a grey background color */
    input:not([disabled]):hover::before {
      box-shadow: 0 1px 5px 0 rgba($color-rich-black, 0.07), 0 0 0 1px tint($color-rich-black, 60%);
    }

    input:checked::before {
      transition: box-shadow 0.2s ease;
      background-color: $color-bleu-de-france;
      box-shadow: inset 0 0 0 1px $color-bleu-de-france, 0 0 0 1px $color-bleu-de-france;
      outline: 0;
    }

    /*Checkmark of the fake checkbox*/
    input::after {
      height: 5px;
      width: 10px;
      border-left: 2px solid $color-white;
      border-bottom: 2px solid $color-white;

      transform: rotate(-45deg);

      left: 2px;
      top: 3px;
    }

    /*Hide the checkmark by default*/
    input[type="checkbox"]::after {
      content: none;
    }

    /*Unhide on the checked state*/
    input[type="checkbox"]:checked::after {
      content: "";
    }

    /*Adding focus styles on the outer-box of the fake checkbox*/
    input[type="checkbox"]:focus::before {
      transition: box-shadow $duration-quickly ease;
      box-shadow: inset 0 0 0 1px $color-bleu-de-france, 0 0 0 1px $color-bleu-de-france;
    }
  }

  .lux-data-table-currency {
    text-align: right;
  }

  .lux-data-table-currency > span::before {
    content: "$";
  }

  .lux-data-table-number {
    text-align: right;
  }

  .lux-data-table-left {
    text-align: left;
  }

  .lux-data-table-center {
    text-align: center;
  }

  .lux-data-table-right {
    text-align: right;
  }
}
</style>
