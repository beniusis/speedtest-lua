<template>
  <a-modal
    :visible="isVisible"
    title="Server List"
    :closable="false"
    :footer="null"
    @cancel="$emit('closeModal')"
    :width="1000"
  >
    <a-input
      v-model="searchInput"
      placeholder="Search for the country, city or provider..."
      style="margin-bottom: 20px;"
      @keyup.enter="filterServers"
    />
    <a-list
      item-layout="horizontal"
      :data-source="filteredServers[0]"
      :pagination="true"
      :loading="loading"
      bordered
    >
      <a-list-item slot="renderItem" slot-scope="server">
        <template #actions>
          <a-button
            type="primary"
            @click="chooseServer(server)"
          >Choose</a-button>
        </template>
        <a-list-item-meta
          :description="server.city + ', ' + server.country"
        >
          <h3 slot="title">{{ server.provider }}</h3>
        </a-list-item-meta>
      </a-list-item>
    </a-list>
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
  },
  data () {
    return {
      loading: true,
      columns: [
        {
          title: 'Provider',
          dataIndex: 'provider'
        },
        {
          title: 'City',
          dataIndex: 'city'
        },
        {
          title: 'Country',
          dataIndex: 'country'
        },
        {
          title: 'Action',
          dataIndex: 'action',
          scopedSlots: { customRender: 'action' }
        }
      ],
      servers: [],
      filteredServers: [],
      searchInput: '',
      getServersInterval: null
    }
  },
  watch: {
    servers: {
      handler () {
        clearInterval(this.getServersInterval)
      }
    }
  },
  methods: {
    async getServers () {
      await this.$rpc.call('speedtest', 'get_servers').then((res) => {
        const servers = JSON.parse(res.servers)
        this.servers.push(servers)
        this.filteredServers = this.servers
        this.loading = false
      }).catch(() => {
        this.loading = true
      })
    },

    async pollServers () {
      this.getServersInterval = setInterval(async () => {
        await this.getServers()
      }, 1000)
    },

    filterServers () {
      this.filteredServers = []
      const filtered = this.servers[0].filter(server =>
        server.country.toLowerCase().includes(this.searchInput.toLowerCase()) ||
        server.provider.toLowerCase().includes(this.searchInput.toLowerCase()) ||
        server.city.toLowerCase().includes(this.searchInput.toLowerCase())
      )
      this.filteredServers.push(filtered)
    },

    chooseServer (server) {
      this.$emit('serverChosen', server)
    }
  },
  beforeUpdate () {
    if (this.servers.length === 0) {
      this.pollServers()
    }
  }
}
</script>
