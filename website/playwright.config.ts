import { defineConfig, devices } from '@playwright/test'

/**
 * SnapPrint MVP critical-journey E2E.
 * - `npm run test:e2e` serves the production build and runs mocked-API specs
 *   (no backend required; backend contract is covered by backend pytest).
 * - Point PLAYWRIGHT_API_MOCK=off + VITE_API_URL at a real backend for
 *   live contract runs.
 */
export default defineConfig({
  testDir: './e2e',
  fullyParallel: true,
  retries: process.env.CI ? 2 : 0,
  reporter: [['list']],
  use: {
    baseURL: 'http://127.0.0.1:4174',
    trace: 'on-first-retry',
  },
  webServer: {
    command: 'npm run start -- --port 4174',
    url: 'http://127.0.0.1:4174',
    reuseExistingServer: !process.env.CI,
    timeout: 60_000,
  },
  projects: [
    { name: 'chromium', use: { ...devices['Desktop Chrome'] } },
    {
      name: 'mobile',
      use: { ...devices['Pixel 7'] },
      testMatch: /.*\.(mobile\.)?spec\.ts/,
    },
  ],
})
