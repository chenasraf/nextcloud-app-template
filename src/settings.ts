import { axios } from './axios'
import Settings from './Settings.vue'
import './style.scss'
import { createApp } from 'vue'

console.log('[DEBUG] Mounting NextcloudAppTemplate Settings')
console.log('[DEBUG] Base URL:', axios.defaults.baseURL)
createApp(Settings).mount('#jukebox-settings')
