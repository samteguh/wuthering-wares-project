const express = require('express');
const router = express.Router();
const db = require('../db');
const { verifyToken, verifyAdmin } = require('../middleware/auth');

// GET /api/equipments - semua equipment (public)
router.get('/', async (req, res) => {
  try {
    const [rows] = await db.query('SELECT * FROM equipment ORDER BY id ASC');
    res.json(rows);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// GET /api/equipments/:id - detail equipment (public)
router.get('/:id', async (req, res) => {
  try {
    const [rows] = await db.query('SELECT * FROM equipment WHERE id = ?', [req.params.id]);
    if (rows.length === 0) return res.status(404).json({ error: 'Equipment not found.' });
    res.json(rows[0]);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// POST /api/equipments - tambah equipment (admin only)
router.post('/', verifyAdmin, async (req, res) => {
  const { name, type, description, stock, image, price } = req.body;

  if (!name || !type || !price) {
    return res.status(400).json({ error: 'Name, type, and price are required.' });
  }
  if (stock < 0) {
    return res.status(400).json({ error: 'Stock cannot be negative.' });
  }
  if (price <= 0) {
    return res.status(400).json({ error: 'Price must be greater than 0.' });
  }

  try {
    const [result] = await db.query(
      'INSERT INTO equipment (name, type, description, stock, image, price) VALUES (?, ?, ?, ?, ?, ?)',
      [name, type, description || '', stock || 0, image || '', price]
    );
    const [newItem] = await db.query('SELECT * FROM equipment WHERE id = ?', [result.insertId]);
    res.status(201).json({ message: 'Equipment created.', equipment: newItem[0] });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// PUT /api/equipments/:id - update equipment (admin only)
router.put('/:id', verifyAdmin, async (req, res) => {
  const { name, type, description, stock, image, price } = req.body;

  if (!name || !type || !price) {
    return res.status(400).json({ error: 'Name, type, and price are required.' });
  }

  try {
    const [existing] = await db.query('SELECT id FROM equipment WHERE id = ?', [req.params.id]);
    if (existing.length === 0) return res.status(404).json({ error: 'Equipment not found.' });

    await db.query(
      'UPDATE equipment SET name=?, type=?, description=?, stock=?, image=?, price=? WHERE id=?',
      [name, type, description, stock, image, price, req.params.id]
    );
    const [updated] = await db.query('SELECT * FROM equipment WHERE id = ?', [req.params.id]);
    res.json({ message: 'Equipment updated.', equipment: updated[0] });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// DELETE /api/equipments/:id - hapus equipment (admin only)
router.delete('/:id', verifyAdmin, async (req, res) => {
  try {
    const [existing] = await db.query('SELECT id FROM equipment WHERE id = ?', [req.params.id]);
    if (existing.length === 0) return res.status(404).json({ error: 'Equipment not found.' });

    await db.query('DELETE FROM equipment WHERE id = ?', [req.params.id]);
    res.json({ message: 'Equipment deleted.' });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

module.exports = router;
