<template>
  <div style="display: flex; flex-direction: column; gap: 10px;">
    <div>
      Country: <strong>{{ country }}</strong>
    </div>
  </div>
</template>

<script>
export default {
  data () {
    return {
      country: ''
    }
  },

  methods: {
    async getCountry () {
      this.$spin(true)
      await this.$rpc.call('speedtest', 'get_country').then((res) => {
        this.country = res.country
        this.$spin(false)
      }).catch(err => console.log(err))
    }
  },

  created () {
    this.getCountry()
  }
}
</script>
