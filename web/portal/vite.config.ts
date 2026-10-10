import react from '@vitejs/plugin-react';
import { defineConfig } from 'vite';

// BASE_PATH is set by CI for GitHub Pages (e.g. /sajag/); local dev serves from /.
export default defineConfig({
  base: process.env.BASE_PATH ?? '/',
  plugins: [react()],
  build: {
    target: 'es2022',
    // Explicit browser targets so the CSS minifier emits vendor prefixes (e.g. -webkit-backdrop-filter
    // for older Safari) alongside the standard property instead of collapsing them into one.
    cssTarget: ['chrome111', 'edge111', 'firefox115', 'safari15', 'ios15'],
    cssCodeSplit: true,
  },
});
