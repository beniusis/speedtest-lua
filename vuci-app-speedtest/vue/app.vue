<template>
  <div class="container">
    <div class="cards-container">
      <InfoCard :title="'Country'" :value="'Country'" :isSpeedData="false" />
      <InfoCard :title="'Server'" :value="'Server'" @click="showServersModal" class="servers-button" :isSpeedData="false" />
      <InfoCard :title="'Download'" :value="0" />
      <InfoCard :title="'Upload'" :value="0" />
    </div>
    <div class="messages-container">
      <h2>{{ message }}</h2>
    </div>
    <div class="gauge-container">
      <vue-gauge :options="{
        chartWidth: 600,
        needleValue: 0,
        hasNeedle: true,
        needleColor: 'black',
        arcDelimiters: [20, 70],
        arcPadding: 10,
        arcColors: ['red', 'yellow', 'green'],
        rangeLabel: ['0 Mbps', '100 Mbps'],
        centralLabel: this.speed,
        arcOverEffect: false
      }" />
    </div>
    <div class="button-container">
      <button>GO</button>
    </div>
    <ServersModal
      :isVisible="isModalVisible"
      @closeModal="closeServersModal"
    />
  </div>
</template>

<script>
import VueGauge from 'vue-gauge'
import ServersModal from './components/ServersModal.vue'
import InfoCard from './components/InfoCard.vue'

export default {
  components: {
    VueGauge,
    ServersModal,
    InfoCard
  },

  data () {
    return {
      country: 'Country',
      bestServer: 'Server',
      speed: '0',
      message: 'Informative message here...',
      isModalVisible: false
    }
  },

  methods: {
    async getCountry () {
      this.$spin(true)
      await this.$rpc.call('speedtest', 'get_country').then((res) => {
        this.country = res.country
        this.$spin(false)
      }).catch(err => console.log(err))
    },

    showServersModal () {
      this.isModalVisible = true
    },

    closeServersModal () {
      this.isModalVisible = false
    }
  },

  created () {
    // this.getCountry()
  }
}
</script>

<style scoped>
.container {
  margin-top: 20px;
  padding: 0;
}

.cards-container {
  display: flex;
  flex-direction: row;
  justify-content: center;
  gap: 20px;
}

.servers-button:hover {
  cursor: pointer;
}

.messages-container {
  display: flex;
  justify-content: center;
  margin-top: 40px;
  font-size: 10px;
}

.gauge-container {
  display: flex;
  justify-content: center;
}

.button-container {
  display: flex;
  justify-content: center;
}

.button-container button {
  width: 100px;
  height: 100px;
  border-radius: 100%;
  background: #fff;
  border: 2px solid black;
  color: black;
  font-size: 32px;
  font-weight: 700;
}

.button-container button:hover {
  cursor: pointer;
  border: 2px solid rgb(92, 92, 92);
  color: rgb(92, 92, 92);
}
</style>
