<template>
  <div>
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

    <h3 class="status-line">{{ displayStatus }}</h3>
    <h2 class="speed-line"><strong>Current test speed: </strong>{{ currentTestSpeed }}</h2>

    <div class="main-container">
      <vue-speedometer
        :maxSegmentLabels="1"
        :segments="6"
        :customSegmentStops='[0, 20, 40, 60, 80, 100]'
        :value="currentTestSpeed > 100 ? 100 : currentTestSpeed"
        currentValueText=""
        :ringWidth="25"
        :minValue="0"
        :maxValue="100"
        :needleHeightRatio="0.85"
        :width="400"
        startColor="#b43a3a"
        endColor="#58fc45"
        needleColor="#2E3440"
        textColor="#2E3440"
        :paddingHorizontal="2"
        :paddingVertical="0"
        labelFontSize="16px"
        needleTransition="easeCircleInOut"
      />
    </div>

    <div class="actions-container">
      <a-button :disabled="isDisabled" type="primary" @click="runTests">Start</a-button>
      <a-button :disabled="isDisabled" @click="showServersModal">Select Server</a-button>
    </div>

    <servers-modal
      :isVisible="isModalVisible"
      @closeModal="closeServersModal"
      @serverSelected="handleSelectedServer"
    />
  </div>
</template>

<script>
import ServersModal from './components/ServersModal.vue'
import VueSpeedometer from 'vue-speedometer'

export default {
  components: {
    ServersModal,
    VueSpeedometer
  },
  data () {
    return {
      country: '',
      server: {},
      currentTestSpeed: 0,
      downloadSpeed: 0,
      uploadSpeed: 0,
      status: '',
      displayStatus: '',
      isModalVisible: false,
      isDisabled: false,
      serverInterval: null
    }
  },
  watch: {
    server: {
      handler () {
        clearInterval(this.serverInterval)
        this.displayStatus = 'Server is set.'
      }
    }
  },
  methods: {
    async getCountry () {
      await this.$rpc.call('speedtest', 'get_country').then((res) => {
        this.country = res.country
      }).catch(() => {
        this.displayStatus = 'Unable to detect your country.'
      })
    },

    async initFindingBestServer () {
      await this.$rpc.call('speedtest', 'start_finding_best_server').then(() => {
        this.displayStatus = 'Initiating the search for the best server available...'
      }).catch(() => {
        this.displayStatus = 'Failed to initiate the search of the best server available.'
      })
    },

    async getBestServer () {
      await this.$rpc.call('speedtest', 'get_best_server').then((res) => {
        this.displayStatus = 'Searching for the best server available...'
        this.server = JSON.parse(res.content)
      }).catch(() => {
        this.displayStatus = 'Still trying to search for the best server available...'
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
        this.displayStatus = 'Starting ' + type + ' test...'
      }).catch(() => {
        this.displayStatus = 'Failed to start the test. Please try again.'
      })
    },

    async runTests () {
      this.isDisabled = true
      this.displayStatus = ''
      this.status = ''
      this.downloadSpeed = 0
      this.uploadSpeed = 0
      await this.getCountry()

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

      // do not start upload test if the download test failed
      // or failed to establish connection to a server
      if (this.status === 'Failed') {
        this.isDisabled = false
        return
      }

      await this.startSpecificTest('upload')
      await this.sleep(3000)
      await this.getResults()

      this.displayStatus = 'Tests finished'
      this.isDisabled = false
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
              this.displayStatus = 'Downloading'
              break
            case 'Uploading':
              this.currentTestSpeed = result.upload
              this.displayStatus = 'Uploading'
              break
            case 'Finished downloading':
              this.currentTestSpeed = 0
              this.downloadSpeed = result.download
              this.displayStatus = 'Finished downloading'
              running = false
              break
            case 'Finished uploading':
              this.currentTestSpeed = 0
              this.uploadSpeed = result.upload
              this.displayStatus = 'Finished uploading'
              running = false
              break
            case 'Connection to server failed':
              this.currentTestSpeed = 0
              this.displayStatus = 'Failed to establish connection to the server. Please choose another server and try again.'
              this.status = 'Failed'
              running = false
              break
            case 'Failed':
              this.currentTestSpeed = 0
              this.downloadSpeed = 0
              this.uploadSpeed = 0
              this.displayStatus = 'Test failed. Please try again.'
              this.status = 'Failed'
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
  }
}
</script>

<style scoped>
.main-container {
  display: flex;
  flex-direction: column;
  justify-content: center;
  align-items: center;
  gap: 20px;
  margin-top: 50px;
}

.info-container {
  display: flex;
  flex-direction: row;
  justify-content: center;
  gap: 50px;
  margin-top: 30px;
  height: 100px;
}

.container {
  display: flex;
  flex-direction: row;
  justify-content: center;
  gap: 10px;
}

.status-line {
  color: lightcoral;
  font-size: 12px;
  text-align: center;
  margin-top: 20px;
  height: 18px;
}

.speed-line {
  margin-top: 10px;
  text-align: center;
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
  gap: 10px;
}
</style>
