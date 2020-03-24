<template>
  <div class="lux-navigator-item documentHeader row">

    <li class="al-collection-context row d-flex align-items-start">

    <div class="">
      <a></a>
    </div>

    <div class="col-auto">
      <a></a>
    </div>

    <div class="col col-no-left-padding d-flex flex-wrap">
      <div class="index_title document-title-heading my-w-75 w-md-100 order-0">
        <a>{{this.pulfaDocument.title}}</a>
      </div>

      <div class="my-w-25 w-md-100 order-12 order-md-1">
        <div class="d-flex justify-content-end">
          Online Content Icon
        </div>
      </div>

      <div class="order-2">
        <div class="row">
          <div class="al-document-abstract-or-scope mb-0">
            <div data-arclight-truncate="true" data-truncate-more="view more ▶" data-truncate-less="view less ▼">
              <div class="responsive-truncate">
                <p>{{this.pulfaDocument.abstract}}</p>
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>

    </li>

  </div>
</template>

<script>
/**


**/

export default {
  name: 'NavigatorItem',
  props: {
    pulfaDocument: {
      type: Object,
      default: null
    }
  }
}

</script>
<style lang="scss" scoped>
</style>
