const express = require('express');
const router = express.Router();
const db = require('../db');
const { verifyToken } = require('../middleware/auth');

// GET /api/orders - order milik user yang login
router.get('/', verifyToken, async (req, res) => {
  try {
    const [rows] = await db.query(
      `SELECT o.id, o.quantity, o.total_price, o.ordered_at,
              e.name AS equipment_name, e.type, e.image, e.price
       FROM orders o
       JOIN equipment e ON o.equipment_id = e.id
       WHERE o.user_id = ?
       ORDER BY o.ordered_at DESC`,
      [req.user.id]
    );
    res.json(rows);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// GET /api/orders/all - semua order (admin only)
router.get('/all', verifyToken, async (req, res) => {
  if (req.user.role !== 'admin') {
    return res.status(403).json({ error: 'Admins only.' });
  }
  try {
    const [rows] = await db.query(
      `SELECT o.id, o.quantity, o.total_price, o.ordered_at,
              u.username, u.email,
              e.name AS equipment_name, e.type, e.price
       FROM orders o
       JOIN users u ON o.user_id = u.id
       JOIN equipment e ON o.equipment_id = e.id
       ORDER BY o.ordered_at DESC`
    );
    res.json(rows);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// POST /api/orders - buat order baru
router.post('/', verifyToken, async (req, res) => {
  const { equipment_id, quantity } = req.body;

  if (!equipment_id || !quantity) {
    return res.status(400).json({ error: 'Equipment ID and quantity are required.' });
  }
  if (quantity <= 0) {
    return res.status(400).json({ error: 'Quantity must be at least 1.' });
  }

  try {
    const [equipRows] = await db.query('SELECT * FROM equipment WHERE id = ?', [equipment_id]);
    if (equipRows.length === 0) return res.status(404).json({ error: 'Equipment not found.' });

    const equipment = equipRows[0];
    if (equipment.stock < quantity) {
      return res.status(400).json({ error: `Insufficient stock. Only ${equipment.stock} left.` });
    }

    const total_price = equipment.price * quantity;

    await db.query(
      'INSERT INTO orders (user_id, equipment_id, quantity, total_price) VALUES (?, ?, ?, ?)',
      [req.user.id, equipment_id, quantity, total_price]
    );

    await db.query('UPDATE equipment SET stock = stock - ? WHERE id = ?', [quantity, equipment_id]);

    res.status(201).json({ message: 'Order placed successfully.', total_price });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

module.exports = router;
