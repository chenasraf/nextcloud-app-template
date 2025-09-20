<template>
  <div class="user-inner">
    <!-- Toolbar -->
    <div class="toolbar">
      <div class="toolbar-left">
        <div style="max-width: 320px">
          <NcTextField
            v-model="search"
            :label="strings.searchLabel"
            :placeholder="strings.searchPlaceholder"
            trailing-button-icon="close"
            :show-trailing-button="search !== ''"
            @trailing-button-click="clearSearch"
          />
        </div>
        <NcButton @click="refresh" :disabled="loading">{{ strings.refresh }}</NcButton>
      </div>

      <div class="toolbar-right">
        <NcButton type="secondary" @click="toggleForm">
          {{ formOpen ? strings.hideForm : strings.showForm }}
        </NcButton>
      </div>
    </div>

    <!-- Quick info / doc -->
    <NcNoteCard class="mt-12" type="info">
      <p v-html="strings.quickHelp"></p>
    </NcNoteCard>

    <!-- Add item form -->
    <section v-if="formOpen" class="card mt-16">
      <h3 class="card-title">{{ strings.formHeader }}</h3>
      <div class="row gap-16 align-start">
        <div style="max-width: 260px">
          <NcTextField
            v-model="name"
            :label="strings.nameInputLabel"
            :placeholder="strings.nameInputPlaceholder"
          />
        </div>

        <div style="max-width: 220px">
          <NcSelect
            v-model="themeLabel"
            :options="themeOptionsLabels"
            :input-label="strings.themeLabel"
          />
        </div>

        <div class="row gap-8 align-center">
          <NcButton @click="addFromForm" :disabled="name.trim() === '' || loading">
            {{ strings.add }}
          </NcButton>
          <NcButton type="tertiary" @click="clearForm" :disabled="loading">
            {{ strings.clear }}
          </NcButton>
        </div>
      </div>

      <p class="mt-12">
        {{ strings.livePreview }} <b>{{ previewGreeting }}</b>
      </p>
    </section>

    <!-- Loading state -->
    <div class="center mt-16" v-if="loading">
      <NcLoadingIcon :size="32" />
      <span class="muted ml-8">{{ strings.loading }}</span>
    </div>

    <!-- Empty state -->
    <NcEmptyContent
      v-else-if="filteredHellos.length === 0"
      :title="strings.emptyTitle"
      :description="strings.emptyDesc"
      class="mt-16"
    >
      <template #action>
        <NcButton @click="seedOne">{{ strings.addExample }}</NcButton>
      </template>
    </NcEmptyContent>

    <!-- List -->
    <section v-else class="mt-16">
      <table>
        <thead>
          <tr>
            <th style="width: 50%">{{ strings.colMessage }}</th>
            <th style="width: 30%">{{ strings.colAt }}</th>
            <th style="width: 20%">{{ strings.colActions }}</th>
          </tr>
        </thead>
        <tbody>
          <tr v-for="(hello, idx) in filteredHellos" :key="hello.id">
            <td class="ellipsis">
              <span class="mono">{{ hello.message }}</span>
            </td>
            <td class="nowrap">
              <NcDateTime v-if="hello.at" :timestamp="new Date(hello.at).valueOf()" />
              <span v-else class="muted">{{ strings.never }}</span>
            </td>
            <td>
              <div class="row gap-8">
                <NcButton type="tertiary" @click="duplicate(idx)">{{ strings.duplicate }}</NcButton>
                <NcButton type="error" @click="remove(idx)">{{ strings.remove }}</NcButton>
              </div>
            </td>
          </tr>
        </tbody>
      </table>

      <!-- Footer actions -->
      <div class="row gap-12 mt-12">
        <NcButton type="secondary" @click="refresh" :disabled="loading">{{
          strings.refresh
        }}</NcButton>
        <NcButton type="secondary" @click="clearAll" :disabled="loading || hellos.length === 0">
          {{ strings.clearAll }}
        </NcButton>
      </div>
    </section>
  </div>
</template>

<script>
/**
 * Inner view rendered inside AppUserWrapper via <router-view>.
 * Matches your style: Options API, Nextcloud UI, axios, i18n placeholders.
 * Uses the Hello controller (GET/POST /hello).
 */
import NcButton from '@nextcloud/vue/components/NcButton'
import NcNoteCard from '@nextcloud/vue/components/NcNoteCard'
import NcTextField from '@nextcloud/vue/components/NcTextField'
import NcSelect from '@nextcloud/vue/components/NcSelect'
import NcEmptyContent from '@nextcloud/vue/components/NcEmptyContent'
import NcLoadingIcon from '@nextcloud/vue/components/NcLoadingIcon'
import NcDateTime from '@nextcloud/vue/components/NcDateTime'

import axios from '@nextcloud/axios'
import { t, n } from '@nextcloud/l10n'

export default {
  name: 'AppUserHome',
  components: {
    NcButton,
    NcNoteCard,
    NcTextField,
    NcSelect,
    NcEmptyContent,
    NcLoadingIcon,
    NcDateTime,
  },
  data() {
    return {
      loading: false,
      formOpen: true,

      // Toolbar
      search: '',

      // Form data
      name: '',
      themeLabel: null,
      themeOptions: [
        { label: t('nextcloud-hello-world', 'Light'), value: 'light' },
        { label: t('nextcloud-hello-world', 'Dark'), value: 'dark' },
        {
          label: n('nextcloud-hello-world', 'System (1 option)', 'System (%n options)', 2),
          value: 'system',
        },
      ],

      // List of "hellos"
      hellos: [],

      strings: {
        // Toolbar
        searchLabel: t('nextcloud-hello-world', 'Search'),
        searchPlaceholder: t('nextcloud-hello-world', 'Filter messages…'),
        refresh: t('nextcloud-hello-world', 'Refresh'),
        showForm: t('nextcloud-hello-world', 'Show form'),
        hideForm: t('nextcloud-hello-world', 'Hide form'),

        // Info
        quickHelp: t(
          'nextcloud-hello-world',
          'Use the form to post a hello. The list shows recent hellos fetched from the server. All user-visible text is centralized in {cStart}strings{cEnd}.',
          { cStart: '<code>', cEnd: '</code>' },
          undefined,
          { escape: false },
        ),

        // Form
        formHeader: t('nextcloud-hello-world', 'Say hello'),
        nameInputLabel: t('nextcloud-hello-world', 'Name'),
        nameInputPlaceholder: t('nextcloud-hello-world', 'e.g. Ada'),
        themeLabel: t('nextcloud-hello-world', 'Theme'),
        add: t('nextcloud-hello-world', 'Add'),
        clear: t('nextcloud-hello-world', 'Clear'),
        livePreview: t('nextcloud-hello-world', 'Preview:'),

        // List
        loading: t('nextcloud-hello-world', 'Loading…'),
        emptyTitle: t('nextcloud-hello-world', 'No hellos yet'),
        emptyDesc: t('nextcloud-hello-world', 'Try adding one using the form above.'),
        addExample: t('nextcloud-hello-world', 'Add example'),
        colMessage: t('nextcloud-hello-world', 'Message'),
        colAt: t('nextcloud-hello-world', 'Time'),
        colActions: t('nextcloud-hello-world', 'Actions'),
        duplicate: t('nextcloud-hello-world', 'Duplicate'),
        remove: t('nextcloud-hello-world', 'Remove'),
        clearAll: t('nextcloud-hello-world', 'Clear all'),
        never: t('nextcloud-hello-world', 'Never'),
      },
    }
  },
  created() {
    this.refresh()
  },
  computed: {
    themeOptionsLabels() {
      return this.themeOptions.map((x) => x.label)
    },
    activeTheme() {
      return this.themeOptions.find((x) => x.label === this.themeLabel) ?? this.themeOptions[0]
    },
    previewGreeting() {
      const n = this.name.trim()
      return n ? `Hello, ${n}!` : 'Hello!'
    },
    filteredHellos() {
      const q = this.search.trim().toLowerCase()
      if (!q) return this.hellos
      return this.hellos.filter((h) => h.message.toLowerCase().includes(q))
    },
  },
  methods: {
    toggleForm() {
      this.formOpen = !this.formOpen
    },
    clearForm() {
      this.name = ''
      this.themeLabel = null
    },
    clearSearch() {
      this.search = ''
    },

    async refresh() {
      try {
        this.loading = true
        // GET /hello -> { ocs: { data: { message, at } } }
        const resp = await axios.get('/hello')
        const data = resp?.data?.ocs?.data ?? {}
        if (data?.message) {
          this.hellos.unshift({
            id: genId(),
            message: data.message,
            at: data.at ?? null,
          })
        }
      } catch (e) {
        console.error('Failed to refresh', e)
      } finally {
        this.loading = false
      }
    },

    async addFromForm() {
      const name = this.name.trim()
      if (!name) return
      try {
        this.loading = true
        const payload = {
          name,
          theme: this.activeTheme.value,
          items: [],
          counter: 0,
        }
        // POST /hello -> { ocs: { data: { message, at } } }
        const resp = await axios.post('/hello', { data: payload })
        const data = resp?.data?.ocs?.data ?? {}
        const message = data?.message ?? `Hello, ${name}!`
        const at = data?.at ?? new Date().toISOString()
        this.hellos.unshift({ id: genId(), message, at })
        this.clearForm()
        this.formOpen = false
      } catch (e) {
        console.error('Failed to add hello', e)
      } finally {
        this.loading = false
      }
    },

    duplicate(index) {
      const src = this.hellos[index]
      if (!src) return
      this.hellos.splice(index + 1, 0, { ...src, id: genId() })
    },

    remove(index) {
      this.hellos.splice(index, 1)
    },

    clearAll() {
      this.hellos = []
    },

    seedOne() {
      this.hellos.push({
        id: genId(),
        message: '👋 Hello example',
        at: new Date().toISOString(),
      })
    },
  },
}

function genId() {
  return Math.random().toString(36).slice(2, 10)
}
</script>

<style scoped lang="scss">
.user-inner {
  .muted {
    color: var(--color-text-maxcontrast);
    opacity: 0.7;
  }

  .mono {
    font-family: var(--font-monospace);
  }

  .mt-8 {
    margin-top: 8px;
  }

  .mt-12 {
    margin-top: 12px;
  }

  .mt-16 {
    margin-top: 16px;
  }

  .ml-8 {
    margin-left: 8px;
  }

  .center {
    display: flex;
    align-items: center;
    justify-content: center;
  }

  .toolbar {
    margin-top: 8px;
    display: flex;
    justify-content: space-between;
    gap: 16px;

    .toolbar-left,
    .toolbar-right {
      display: flex;
      align-items: center;
      gap: 12px;
    }
  }

  .row {
    display: flex;

    &.align-start {
      align-items: flex-start;
    }

    &.align-center {
      align-items: center;
    }

    &.gap-8 {
      gap: 8px;
    }

    &.gap-12 {
      gap: 12px;
    }

    &.gap-16 {
      gap: 16px;
    }
  }

  .card {
    border: 1px solid var(--color-border);
    border-radius: 8px;
    padding: 12px;
    background: var(--color-main-background);
  }

  .card-title {
    margin: 0 0 8px 0;
    font-size: 1rem;
    font-weight: 600;
  }

  table {
    width: 100%;
    border-collapse: collapse;
    border: 1px solid var(--color-border);

    thead tr,
    tr:not(:last-child) {
      border-bottom: 1px solid var(--color-border);
    }

    thead,
    tbody tr {
      display: table;
      width: 100%;
      table-layout: fixed;
    }

    th,
    td {
      padding: 8px;
      vertical-align: middle;
    }

    .nowrap {
      white-space: nowrap;
    }

    .ellipsis {
      overflow: hidden;
      text-overflow: ellipsis;
      white-space: nowrap;
    }
  }
}
</style>
