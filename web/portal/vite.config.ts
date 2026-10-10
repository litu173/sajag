import react from '@vitejs/plugin-react';
import { defineConfig } from 'vite';

// BASE_PATH is set by CI for GitHub Pages (e.g. /sajag/); local dev serves from /.
export default defineConfig({
  base: process.env.BASE_PATH ?? '/',
  plugins: [react()],
  build: { target: 'es2022', cssCodeSplit: true },
});
