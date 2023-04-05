<template>
  <div class="container">
    <vue-gauge v-if="isGaugeVisible" :options="{
      chartWidth: 500,
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
    <button v-if="!isGaugeVisible" class="start-test-button" @click="startTest">GO</button>
    <div class="message-container">
      {{ message }}
    </div>
    <div class="info-container">
      <div class="left-container">
        <div class="left-info">
          <h2 class="country">Country</h2>
          <h3 class="country-value"><strong>{{ country }}</strong></h3>
        </div>
        <div class="left-icon">
          <a-icon type="user" />
        </div>
      </div>
      <div class="right-container">
        <div class="right-icon">
          <a-icon type="global" />
        </div>
        <div class="right-info">
          <h2 class="provider">{{ bestServer.provider }}</h2>
          <h3 class="location">{{ bestServer.city }}</h3>
          <p class="change-server-button" @click="showServersModal"><strong>Change Server</strong></p>
        </div>
      </div>
    </div>
    <ServersModal :isVisible="isModalVisible" @closeModal="closeServersModal" @serverChosen="handleServerChosen" />
  </div>
</template>

<script>
import VueGauge from 'vue-gauge'
import ServersModal from './components/ServersModal.vue'

export default {
  components: {
    VueGauge,
    ServersModal
  },
  data () {
    return {
      country: '',
      bestServer: {},
      speed: '0',
      message: '',
      isModalVisible: false,
      isGaugeVisible: false,
      bestServerInterval: null
    }
  },
  watch: {
    bestServer: {
      handler () {
        clearInterval(this.bestServerInterval)
        this.message = ''
      }
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

    initBestServer () {
      this.$rpc.call('speedtest', 'start_finding_best_server').then((res) => {
        this.message = res.content
      }).catch(err => console.log(err))
    },

    async getBestServer () {
      await this.$rpc.call('speedtest', 'get_best_server').then((res) => {
        this.bestServer = JSON.parse(res.content)
      }).catch(err => console.log(err))
    },

    pollBestServer () {
      this.bestServerInterval = setInterval(() => {
        this.getBestServer()
      }, 1000)
    },

    startTest () {
      this.isGaugeVisible = true
    },

    handleServerChosen (server) {
      this.closeServersModal()
      this.bestServer.provider = server.provider
      this.bestServer.city = server.city
      this.bestServer.server = server.host
    },

    showServersModal () {
      this.isModalVisible = true
    },

    closeServersModal () {
      this.isModalVisible = false
    }
  },
  created () {
    this.getCountry()
    this.initBestServer()
    this.pollBestServer()
  }
}
</script>

<style scoped>
.container {
  display: flex;
  flex-direction: column;
  justify-content: center;
  align-items: center;
  margin-top: 30px;
  padding: 0;
}

.start-test-button {
  color: black;
  font-size: 28px;
  font-weight: 700;
  background: none;
  border: 2px solid black;
  border-radius: 100%;
  width: 100px;
  height: 100px;
}

.start-test-button:hover {
  cursor: pointer;
  opacity: .5;
}

.info-container {
  display: flex;
  flex-direction: row;
  justify-content: center;
  gap: 30px;
  width: 300px;
}

.info-container .left-container {
  display: flex;
  flex-direction: row;
  text-align: right;
  gap: 10px;
}

.country {
  font-size: 18px;
}

.country-value {
  font-size: 14px;
}

.provider {
  font-size: 18px;
}

.location {
  font-size: 14px;
}

.info-container .right-container {
  display: flex;
  flex-direction: row;
  text-align: left;
  gap: 10px;
}

.change-server-button {
  color: rgb(84, 132, 230);
}

.change-server-button:hover {
  cursor: pointer;
  color: rgb(141, 206, 255)
}

.message-container {
  font-size: 14px;
  color: black;
  opacity: .5;
  margin: 20px;
}
</style>
