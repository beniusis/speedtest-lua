<template>
  <a-modal :visible="isVisible" title="Basic Modal" :closable="false" :footer="null" @cancel="$emit('closeModal')">
  </a-modal>
</template>

<script>
export default {
  name: 'ServersModal',
  props: {
    isVisible: {
      type: Boolean,
      default: false
    }
  }
}
</script>
