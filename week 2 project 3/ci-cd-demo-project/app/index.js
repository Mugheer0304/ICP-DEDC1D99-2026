const express = require('express');

const app = express();
app.use(express.json());

// A tiny "business logic" function we will unit test
function add(a, b) {
  if (typeof a !== 'number' || typeof b !== 'number') {
    throw new Error('Both arguments must be numbers');
  }
  return a + b;
}

function isEven(n) {
  return n % 2 === 0;
}

app.get('/', (req, res) => {
  res.json({ message: 'CI/CD Demo API is running', version: process.env.APP_VERSION || 'dev' });
});

app.get('/health', (req, res) => {
  res.status(200).json({ status: 'ok' });
});

app.post('/add', (req, res) => {
  try {
    const { a, b } = req.body;
    const result = add(a, b);
    res.json({ result, isEven: isEven(result) });
  } catch (err) {
    res.status(400).json({ error: err.message });
  }
});

// Only start the server if this file is run directly (not when imported by tests)
if (require.main === module) {
  const PORT = process.env.PORT || 3000;
  app.listen(PORT, () => {
    console.log(`Server listening on port ${PORT}`);
  });
}

module.exports = { app, add, isEven };
// trigger full pipeline test
