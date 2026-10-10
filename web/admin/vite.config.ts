import react from '@vitejs/plugin-react';
import { defineConfig } from 'vite';

// Served from <BASE_PATH>admin/ next to the portal on GitHub Pages.
export default defineConfig({
  base: `${process.env.BASE_PATH ?? '/'}admin/`,
  plugins: [react()],
  build: {
    target: 'es2022',
    // Explicit browser targets so the CSS minifier emits vendor prefixes (e.g. -webkit-backdrop-filter
    // for older Safari) alongside the standard property instead of collapsing them into one.
    cssTarget: ['chrome111', 'edge111', 'firefox115', 'safari15', 'ios15'],
  },
});
