
<template>
  <div class="lux-navigator-item">

    <div class="">
      <a></a>
    </div>
    <div class="col-auto">
      <a></a>
    </div>
    <div>
      <div>
        <a>{this.pulfaDocument.title}</a>
      </div>
      <div>
        Request
      </div>
      <div>
        <div class="row">
          <p>{this.pulfaDocument.abstract}</p>
        </div>
      </div>
    </div>

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
