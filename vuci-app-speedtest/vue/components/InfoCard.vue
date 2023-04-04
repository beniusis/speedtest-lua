<template>
  <a-col :xs="{ span: 4, offset: 0 }">
    <a-card>
      <a-statistic
        v-if="!isSpeedData"
        :title="this.title"
        :value="this.value"
      >
      </a-statistic>
      <a-statistic
        v-else
        :title="this.title"
        :value="this.value"
        :precision="2"
        suffix="Mbps"
        style="margin-right: 50px"
      >
        <template #prefix>
          <a-icon :type="iconType" />
        </template>
      </a-statistic>
    </a-card>
  </a-col>
</template>

<script>
export default {
  name: 'InfoCard',
  props: {
    isSpeedData: {
      type: Boolean,
      default: true
    },
    title: {
      type: String,
      default: '',
      required: true
    },
    value: {
      type: [Number, String],
      default: null,
      required: true
    }
  },
  computed: {
    iconType () {
      if (this.title === 'Download') {
        return 'arrow-down'
      } else if (this.title === 'Upload') {
        return 'arrow-up'
      } else return null
    }
  }
}
</script>
