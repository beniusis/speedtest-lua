<template>
  <div>
    <div class="main-container">
      <div class="speed-meter-container">
        <div style="margin-top: 130px;">
          <h3><strong>0</strong></h3>
        </div>
        <vue-svg-gauge
          :start-angle="-90"
          :end-angle="90"
          :value="this.currentTestSpeed"
          :separator-step="0"
          :inner-radius="80"
          :min="0"
          :max="100"
          :gauge-color="[{ offset: 0, color: '#b43a3a'}, { offset: 70, color: '#fdfb1d'}, { offset: 100, color: '#58fc45'}]"
          :scale-interval="0"
          :easing="'Circular.InOut'"
          :transition-duration="500"
        />
        <div style="margin-top: 130px;">
          <h3><strong>100</strong></h3>
        </div>
      </div>
      <div class="status-container">
        <h3 style="color: lightcoral; font-size: 12px;">{{ status }}</h3>
      </div>
      <div class="speed-container">
        <h2><strong>Current test speed: </strong>{{ currentTestSpeed }}</h2>
      </div>
    </div>
    <div class="info-container">
      <div class="container">
        <v-icon name="hi-solid-location-marker" class="icon" />
        <h2>{{ country }}</h2>
      </div>
      <div class="container" style="max-width: 200px;">
        <v-icon name="ri-global-line" class="icon" />
        <div style="dislay: flex; flex-direction: column;">
          <h2>{{ server.provider }}</h2>
          <h3>{{ server.city }}</h3>
          <p
            class="change-server-button"
            @click="showServersModal">
              <strong>Select Server</strong>
          </p>
        </div>
      </div>
      <div class="container">
        <v-icon name="ri-download-cloud-line" class="icon" />
        <h2>{{ downloadSpeed }} Mbps</h2>
      </div>
      <div class="container">
        <v-icon name="ri-upload-cloud-line" class="icon" />
        <h2>{{ uploadSpeed }} Mbps</h2>
      </div>
    </div>

    <div class="actions-container">
      <a-button type="primary" @click="runTests">GO</a-button>
    </div>

    <ServersModal
      :isVisible="isModalVisible"
      @closeModal="closeServersModal"
      @serverChosen="handleServerChosen"
    />
  </div>
</template>

<script>
import ServersModal from './components/ServersModal.vue'
import { VueSvgGauge } from 'vue-svg-gauge'

export default {
  components: {
    ServersModal,
    VueSvgGauge
  },
  data () {
    return {
      country: '',
      server: {},
      currentTestSpeed: 0,
      downloadSpeed: 0,
      uploadSpeed: 0,
      status: '',
      isModalVisible: false,
      serverInterval: null,
      isAuto: true
    }
  },
  watch: {
    server: {
      handler () {
        clearInterval(this.serverInterval)
        this.status = 'Server is set. Getting ready for the tests.'
      }
    }
  },
  methods: {
    async getCountry () {
      this.$spin(true)
      await this.$rpc.call('speedtest', 'get_country').then((res) => {
        this.country = res.country
      }).catch(() => {
        this.status = 'Unable to detect your country.'
      }).finally(() => this.$spin(false))
    },

    async initFindingBestServer () {
      await this.$rpc.call('speedtest', 'start_finding_best_server').then(() => {
        this.status = 'Searching for the best server...'
      }).catch(() => {
        this.status = 'Failed while searching for the best server! Try again.'
      })
    },

    async getBestServer () {
      await this.$rpc.call('speedtest', 'get_best_server').then((res) => {
        this.server = JSON.parse(res.content)
      }).catch(() => {
        this.status = 'Failed to get the best server! Try again.'
      })
    },

    pollBestServer () {
      this.initFindingBestServer()
      this.serverInterval = setInterval(() => {
        this.getBestServer()
      }, 1000)
    },

    async startAutoTest () {
      await this.$rpc.call('speedtest', 'automatic_test').then(() => {
        this.status = 'Starting automatic test...'
      }).catch(() => {
        this.status = 'Failed to start the test! Try again.'
      })
    },

    // testType - download/upload
    async startSpecificTest (testType) {
      await this.$rpc.call('speedtest', 'specific_test', { server: this.server.server, type: testType }).then(() => {
        this.status = 'Starting ' + testType + ' test...'
      }).catch(() => {
        this.status = 'Failed to start the test! Try again.'
      })
    },

    async runTests () {
      // by default automatic test to the best server
      // else - specific (to a chosen server)
      if (Object.keys(this.server).length === 0) {
        this.downloadSpeed = 0
        this.uploadSpeed = 0
        this.pollBestServer()
        await this.startAutoTest()
        await this.sleep(3000)
        await this.getResults()
      } else {
        this.downloadSpeed = 0
        this.uploadSpeed = 0
        this.isAuto = false
        await this.startSpecificTest('download')
        await this.sleep(3000)
        await this.getResults()
        await this.startSpecificTest('upload')
        await this.sleep(3000)
        await this.getResults()
      }
    },

    async getResults () {
      let running = true
      while (running) {
        const res = await this.$rpc.call('speedtest', 'get_results')
        if (res.results !== '') {
          const result = JSON.parse(res.results)
          this.status = result.status
          if (result.status === 'Downloading') {
            this.currentTestSpeed = result.download
          } else if (result.status === 'Uploading') {
            this.currentTestSpeed = result.upload
          } else if (result.status === 'Finished downloading') {
            this.currentTestSpeed = 0
            this.downloadSpeed = result.download
            if (this.isAuto === false) running = false
          } else if (result.status === 'Finished uploading') {
            this.currentTestSpeed = 0
            this.uploadSpeed = result.upload
            running = false
          } else if (result.status === 'Failed') {
            this.currentTestSpeed = 0
            this.downloadSpeed = 0
            this.uploadSpeed = 0
            this.status = 'Test failed! Try again.'
            running = false
          }
        }
        await this.sleep(500)
      }
    },

    sleep (ms) {
      return new Promise(resolve => setTimeout(resolve, ms))
    },

    handleServerChosen (server) {
      this.closeServersModal()
      this.server.provider = server.provider
      this.server.city = server.city
      this.server.server = server.host
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
  }
}
</script>

<style scoped>
.main-container {
  display: flex;
  flex-direction: column;
  justify-content: center;
  align-items: center;
  margin-top: 20px;
  margin-bottom: 50px;
  gap: 20px;
}

.speed-meter-container {
  display: flex;
  flex-direction: row;
  gap: 10px;
}

.info-container {
  display: flex;
  flex-direction: row;
  justify-content: center;
  gap: 50px;
}

.container {
  display: flex;
  flex-direction: row;
  justify-content: center;
  gap: 10px;
}

.icon {
  width: 30px;
  height: 30px;
}

.change-server-button {
  color: rgb(84, 132, 230);
}

.change-server-button:hover {
  cursor: pointer;
  color: rgb(141, 206, 255)
}

.actions-container {
  display: flex;
  justify-content: center;
  align-items: center;
  margin-top: 50px;
}
</style>
