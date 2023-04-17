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
      <div class="container" style="max-width: 250px;">
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
      @serverSelected="handleSelectedServer"
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
      serverInterval: null
    }
  },
  watch: {
    server: {
      handler () {
        clearInterval(this.serverInterval)
        this.status = 'Server is set.'
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
        this.status = 'Initiating the search for the best server available...'
      }).catch(() => {
        this.status = 'Failed to initiate the search of the best server available.'
      })
    },

    async getBestServer () {
      await this.$rpc.call('speedtest', 'get_best_server').then((res) => {
        this.status = 'Searching for the best server available...'
        this.server = JSON.parse(res.content)
      }).catch(() => {
        this.status = 'Still trying to search for the best server available...'
      })
    },

    async pollBestServer () {
      await this.initFindingBestServer()
      this.serverInterval = setInterval(async () => {
        await this.getBestServer()
      }, 1000)
    },

    // type - download/upload
    async startSpecificTest (type) {
      await this.$rpc.call('speedtest', 'specific_test', { server: this.server.host, type: type }).then(() => {
        this.status = 'Starting ' + type + ' test...'
      }).catch(() => {
        this.status = 'Failed to start the test. Please try again.'
      })
    },

    async runTests () {
      this.downloadSpeed = 0
      this.uploadSpeed = 0

      // check if the server is not selected
      // if it's not selected - search for the best server available first
      if (Object.keys(this.server).length === 0) {
        await this.pollBestServer()
        await this.sleep(3000)
      }

      // run download and upload tests one after another
      await this.startSpecificTest('download')
      await this.sleep(3000)
      await this.getResults()
      await this.startSpecificTest('upload')
      await this.sleep(3000)
      await this.getResults()
    },

    async getResults () {
      let running = true
      while (running) {
        const res = await this.$rpc.call('speedtest', 'get_results')
        if (res.results !== '') {
          const result = JSON.parse(res.results)
          switch (result.status) {
            case 'Downloading':
              this.currentTestSpeed = result.download
              this.status = 'Downloading'
              break
            case 'Uploading':
              this.currentTestSpeed = result.upload
              this.status = 'Uploading'
              break
            case 'Finished downloading':
              this.currentTestSpeed = 0
              this.downloadSpeed = result.download
              this.status = 'Finished downloading'
              running = false
              break
            case 'Finished uploading':
              this.currentTestSpeed = 0
              this.uploadSpeed = result.upload
              this.status = 'Finished uploading'
              running = false
              break
            case 'Failed':
              this.currentTestSpeed = 0
              this.downloadSpeed = 0
              this.uploadSpeed = 0
              this.status = 'Test failed. Please try again.'
              running = false
              break
          }
        }
        await this.sleep(500)
      }
    },

    sleep (ms) {
      return new Promise(resolve => setTimeout(resolve, ms))
    },

    handleSelectedServer (server) {
      this.closeServersModal()
      this.server = server
    },

    showServersModal () {
      this.isModalVisible = true
    },

    closeServersModal () {
      this.isModalVisible = false
    }
  },
  async created () {
    await this.getCountry()
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
  min-width: 30px;
  min-height: 30px;
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
