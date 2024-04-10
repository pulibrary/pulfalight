<template>
  <div>
    <template v-if="embedStatus === 'authorized'">
      <template v-if="embedType === 'html'">
        <div v-html="embedContent" id="uv_div" class="intrinsic-container intrinsic-container-16x9 uv__overlay">
        </div>
      </template>
      <template v-if="embedType === 'link'">
        <lux-hyperlink :href="embedContent" variation="button solid"
                                       size="large">{{ linkLabel }}</lux-hyperlink>
      </template>
    </template>
    <template v-else-if="embedStatus === 'unauthenticated'">
      <div style="border-radius: 3px; background: #fee7ba; padding: 20px;
           margin-bottom: 2em;">
        <p>Please contact Special Collections staff through the <a
          href='https://library.princeton.edu/special-collections/ask-us'>Ask
          Us! form</a> for access to this collection. <button @click="figgyLogin" id='login' class='btn' >Use your Princeton credentials to login.</button></p>
      </div>
    </template>
  </div>
</template>
<script>
export default {
  name: "FiggyViewer",
  props: {
    componentId: String,
    daoLabel: String,
    daoLink: String
  },
  data() {
    return {
      embedStatus: null,
      embedContent: null,
      embedType: null
    }
  },
  computed: {
    linkLabel() {
      if(this.daoLabel == '' || this.embedContent != this.daoLink)
        return "Download Content"
      else
        return this.daoLabel
    }
  },
  async created() {
    return this.updateData()
  },
  methods: {
    async updateData() {
      return this.checkFiggy().then((data) => this.processFiggyResponse(data))
    },
    async checkFiggy() {
      var url = "https://figgy.princeton.edu/graphql";
      var data = JSON.stringify({ query:`{
       resourcesByOrangelightId(id: "` + this.componentId + `"){
         id,
         embed {
          type,
          content,
          status
        }
       }
     }`
      })
      return fetch(url,
        {
          method: "POST",
          credentials: 'include',
          body: data,
          headers: {
            'Content-Type': 'application/json',
          }
        }
      )
        .then((response) => response.json())
        .then((response) => response.data.resourcesByOrangelightId[0])
    },
    processFiggyResponse(data) {
      this.embedType = data.embed.type
      this.embedStatus = data.embed.status
      this.embedContent = data.embed.content
    },
    figgyLogin() {
      let child = window.open('https://figgy.princeton.edu/users/auth/cas?login_popup=true')

      const checkChild = () => {
        if (child.closed) {
          clearInterval(timer)
          this.updateData()
        }
      }
      let timer = setInterval(checkChild, 200)
    }
  }
}
</script>

<style lang="scss" scoped>
</style>
