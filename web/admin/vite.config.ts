import react from '@vitejs/plugin-react';
import { defineConfig } from 'vite';

// Served from <BASE_PATH>admin/ next to the portal on GitHub Pages.
export default defineConfig({
  base: `${process.env.BASE_PATH ?? '/'}admin/`,
  plugins: [react()],
  build: { target: 'es2022' },
});
