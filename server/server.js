const express = require('express');
const sqlite3 = require('sqlite3').verbose();
const cors = require('cors');
const bodyParser = require('body-parser');
const path = require('path');
const fs = require('fs');

const app = express();
const port = 3000;

// Middleware
app.use(cors());
app.use(bodyParser.json());

// Connect to SQLite database
const dbPath = path.join(__dirname, 'fog_of_war.db');
console.log(`Database path: ${dbPath}`);
const db = new sqlite3.Database(dbPath);

// Create tables if they don't exist
db.serialize(() => {
  db.run(`
    CREATE TABLE IF NOT EXISTS users (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      username TEXT UNIQUE NOT NULL,
      password_hash TEXT NOT NULL
    )
  `);

  db.run(`
    CREATE TABLE IF NOT EXISTS exposed_terrain (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      user_id INTEGER NOT NULL,
      latitude REAL NOT NULL,
      longitude REAL NOT NULL,
      FOREIGN KEY (user_id) REFERENCES users (id)
    )
  `);

  console.log('Database tables created or already exist');
});

// API Endpoints

// Register user
app.post('/api/users/register', (req, res) => {
  const { username, password_hash } = req.body;

  console.log(`Registering user: ${username}`);

  db.run(
    'INSERT INTO users (username, password_hash) VALUES (?, ?)',
    [username, password_hash],
    function(err) {
      if (err) {
        console.error('Error registering user:', err.message);
        return res.status(400).json({ error: err.message });
      }

      console.log(`User registered with ID: ${this.lastID}`);
      res.json({ id: this.lastID, username });
    }
  );
});

// Login user
app.post('/api/users/login', (req, res) => {
  const { username, password_hash } = req.body;

  console.log(`Login attempt for user: ${username}`);

  db.get(
    'SELECT id, username FROM users WHERE username = ? AND password_hash = ?',
    [username, password_hash],
    (err, row) => {
      if (err) {
        console.error('Error during login:', err.message);
        return res.status(400).json({ error: err.message });
      }

      if (!row) {
        console.log('Invalid credentials');
        return res.status(401).json({ error: 'Invalid credentials' });
      }

      console.log(`User logged in: ${username}`);
      res.json(row);
    }
  );
});

// Save exposed terrain
app.post('/api/terrain', (req, res) => {
  const { user_id, latitude, longitude } = req.body;

  console.log(`Saving terrain for user ${user_id} at ${latitude}, ${longitude}`);

  db.run(
    'INSERT INTO exposed_terrain (user_id, latitude, longitude) VALUES (?, ?, ?)',
    [user_id, latitude, longitude],
    function(err) {
      if (err) {
        console.error('Error saving terrain:', err.message);
        return res.status(400).json({ error: err.message });
      }

      res.json({ id: this.lastID, user_id, latitude, longitude });
    }
  );
});

// Get exposed terrain for a user
app.get('/api/terrain/:userId', (req, res) => {
  const userId = req.params.userId;

  console.log(`Getting terrain for user ${userId}`);

  db.all(
    'SELECT * FROM exposed_terrain WHERE user_id = ?',
    [userId],
    (err, rows) => {
      if (err) {
        console.error('Error getting terrain:', err.message);
        return res.status(400).json({ error: err.message });
      }

      console.log(`Found ${rows.length} terrain tiles for user ${userId}`);
      res.json(rows);
    }
  );
});

// Check if terrain is exposed
app.get('/api/terrain/:userId/:latitude/:longitude', (req, res) => {
  const { userId, latitude, longitude } = req.params;

  console.log(`Checking if terrain at ${latitude}, ${longitude} is exposed for user ${userId}`);

  db.get(
    'SELECT * FROM exposed_terrain WHERE user_id = ? AND latitude = ? AND longitude = ?',
    [userId, latitude, longitude],
    (err, row) => {
      if (err) {
        console.error('Error checking terrain:', err.message);
        return res.status(400).json({ error: err.message });
      }

      res.json({ exposed: !!row });
    }
  );
});

// Get server status
app.get('/api/status', (req, res) => {
  res.json({ status: 'ok', message: 'Server is running' });
});

// Start the server
app.listen(port, '0.0.0.0', () => {
  console.log(`Server running at http://0.0.0.0:${port}`);
});

// Handle shutdown
process.on('SIGINT', () => {
  console.log('Closing database connection');
  db.close();
  process.exit(0);
});
