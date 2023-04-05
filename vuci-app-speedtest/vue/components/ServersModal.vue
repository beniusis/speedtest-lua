<template>
  <a-modal :visible="isVisible" title="Server List" :closable="false" :footer="null" @cancel="$emit('closeModal')" :width="1000">
    <a-input v-model="searchInput" placeholder="Search for country, city or provider..." style="margin-bottom: 20px;" />
    <!-- <a-list item-layout="horizontal" :data-source="filteredServers[0]" :pagination="true" :loading="loading" bordered>
      <a-list-item slot="renderItem" slot-scope="item">
        <template #actions>
          <a-button type="primary" @click="chosenServer">Choose</a-button>
        </template>
        <a-list-item-meta
          :description="item.city + ', ' + item.country"
        >
          <h3 slot="title">{{ item.provider }}</h3>
        </a-list-item-meta>
      </a-list-item>
    </a-list> -->
    <a-table :columns="columns" :data-source="filteredServers[0]" :rowKey="'id'" :pagination="true" :loading="loading">
      <span slot="action" slot-scope="record, action">
        <a-button type="primary" @click="chosenServer(action)">Choose</a-button>
      </span>
    </a-table>
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
      searchInput: ''
    }
  },
  watch: {
    searchInput () {
      this.filteredServers = []
      const arr = []
      this.servers[0].forEach(server => {
        if (server.country.toLowerCase().includes(this.searchInput.toLowerCase()) ||
          server.provider.toLowerCase().includes(this.searchInput.toLowerCase()) ||
          server.city.toLowerCase().includes(this.searchInput.toLowerCase())) {
          arr.push(server)
        }
      })
      this.filteredServers.push(arr)
    }
  },
  methods: {
    async getServers () {
      await this.$rpc.call('speedtest', 'get_servers').then((res) => {
        const servers = JSON.parse(res.servers)
        this.servers.push(servers)
        this.filteredServers = this.servers
        this.loading = false
      }).catch(err => console.log(err))
    },

    chosenServer (server) {
      this.$emit('serverChosen', server)
    }
  },
  beforeUpdate () {
    if (this.servers.length === 0) {
      this.getServers()
    }
  }
}
</script>
