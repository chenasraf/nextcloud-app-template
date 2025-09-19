import App from './App.vue'
import './style.scss'
import { createApp } from 'vue'
import axios from '@nextcloud/axios'
import { generateOcsUrl } from '@nextcloud/router'
import router from './router'

const baseURL = generateOcsUrl('/apps/nextcloud-app-template/api')
axios.defaults.baseURL = baseURL

console.log('[DEBUG] Mounting NextcloudAppTemplate app')
console.log('[DEBUG] Base URL:', baseURL)
createApp(App).use(router).mount('#nextcloud-app-template-app')
