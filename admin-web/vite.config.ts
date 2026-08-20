import { defineConfig } from 'vite'
import react from '@vitejs/plugin-react'

// https://vite.dev/config/
export default defineConfig(({ command }) => {
  const apiUrl = process.env.VITE_API_URL

  if (command === 'build') {
    if (!apiUrl) {
      throw new Error('VITE_API_URL must be set before building admin-web for deployment.')
    }

    const parsedApiUrl = new URL(apiUrl)
    if (parsedApiUrl.protocol !== 'https:') {
      throw new Error('VITE_API_URL must use HTTPS for deployment builds.')
    }
  }

  return {
    plugins: [react()],
  }
})
