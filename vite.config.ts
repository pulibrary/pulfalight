import { defineConfig } from 'vite'
import RubyPlugin from 'vite-plugin-ruby'
import vue from '@vitejs/plugin-vue'

export default defineConfig({
  plugins: [
    RubyPlugin(),
    vue()
  ],
  test: {
    globals: true,
    environment: 'jsdom',
    setupFiles: ['./test/setup.js'],
    alias: {
      '@/': './app/javascript'
    }
  },
  resolve: {
    alias: {
      vue: 'vue/dist/vue.esm-bundler'
    }
  }
})
