const request = require('supertest');
const { app, add, isEven } = require('./index');

describe('Unit tests: pure functions', () => {
  test('add() correctly adds two numbers', () => {
    expect(add(2, 3)).toBe(5);
    expect(add(-1, 1)).toBe(0);
  });

  test('add() throws on invalid input', () => {
    expect(() => add('a', 2)).toThrow('Both arguments must be numbers');
  });

  test('isEven() correctly identifies even numbers', () => {
    expect(isEven(4)).toBe(true);
    expect(isEven(7)).toBe(false);
  });
});

describe('Integration tests: API endpoints', () => {
  test('GET / returns a running message', async () => {
    const res = await request(app).get('/');
    expect(res.statusCode).toBe(200);
    expect(res.body.message).toBe('CI/CD Demo API is running');
  });

  test('GET /health returns ok status', async () => {
    const res = await request(app).get('/health');
    expect(res.statusCode).toBe(200);
    expect(res.body.status).toBe('ok');
  });

  test('POST /add returns correct sum', async () => {
    const res = await request(app).post('/add').send({ a: 4, b: 6 });
    expect(res.statusCode).toBe(200);
    expect(res.body.result).toBe(10);
    expect(res.body.isEven).toBe(true);
  });

  test('POST /add returns 400 on invalid input', async () => {
    const res = await request(app).post('/add').send({ a: 'x', b: 6 });
    expect(res.statusCode).toBe(400);
    expect(res.body.error).toBeDefined();
  });
});
