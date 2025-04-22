import { defineConfig } from 'vite';
import wasm from 'vite-plugin-wasm';
import { nodePolyfills } from 'vite-plugin-node-polyfills'

export default defineConfig({
  plugins: [
    wasm(),
    nodePolyfills(),
  ],
  build: {
    lib: {
      entry: 'src/main.js',
      name: 'LucidBundle',
      fileName: 'lucid-bundle',
      formats: ['es'],
    },
    rollupOptions: {
      output: {
        inlineDynamicImports: true, // ensures one bundle
      }
    },
    target: 'esnext'
  },
  optimizeDeps: {
    exclude: ['@emurgo/cardano-serialization-lib-browser']
  }
});
