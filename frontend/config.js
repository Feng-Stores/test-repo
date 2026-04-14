// Set this to your Container App URL after first backend deployment.
// The CI workflow substitutes __BACKEND_URL__ automatically once
// BACKEND_URL is configured as a GitHub Actions variable.
window.BACKEND_URL =
  typeof __BACKEND_URL__ !== 'undefined'
    ? '__BACKEND_URL__'
    : 'http://localhost:3000';
