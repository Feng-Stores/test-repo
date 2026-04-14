const express = require('express');
const cors = require('cors');

const app = express();
const PORT = process.env.PORT || 3000;

app.use(cors());
app.use(express.json());

app.get('/api/health', (_req, res) => {
  res.json({ status: 'ok', timestamp: new Date().toISOString() });
});

app.get('/api/hello', (_req, res) => {
  res.json({ message: 'Hello from Azure Container App! (v3)' });
});

app.listen(PORT, () => {
  console.log(`Backend listening on port ${PORT}`);
});
