// routes/auth.js (updated version)
const express = require('express');
const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');
const { body, validationResult } = require('express-validator');
const authenticateToken = require('../middleware/auth');
const router = express.Router();

// Register endpoint
router.post('/register', [
  body('email').isEmail().normalizeEmail(),
  body('password').isLength({ min: 6 }),
  body('displayName').optional().isLength({ min: 1, max: 100 })
], async (req, res) => {
  try {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({
        error: 'Validation failed',
        details: errors.array()
      });
    }

    const { email, password, displayName } = req.body;
    const db = req.app.locals.db;

    // Check if user already exists
    const existingUser = await db.query(
      'SELECT id FROM users WHERE email = $1',
      [email]
    );

    if (existingUser.rows.length > 0) {
      return res.status(400).json({
        error: 'User already exists with this email'
      });
    }

    // Hash password
    const saltRounds = 12;
    const passwordHash = await bcrypt.hash(password, saltRounds);

    // Create user
    const result = await db.query(
      `INSERT INTO users (email, password_hash, display_name) 
       VALUES ($1, $2, $3) 
       RETURNING id, email, display_name, created_at`,
      [email, passwordHash, displayName || email.split('@')[0]]
    );

    const user = result.rows[0];

    // Generate JWT token
    const token = jwt.sign(
      { 
        userId: user.id, 
        email: user.email 
      },
      process.env.JWT_SECRET,
      { expiresIn: process.env.JWT_EXPIRES_IN }
    );

    res.status(201).json({
      message: 'User created successfully',
      token,
      user: {
        id: user.id,
        email: user.email,
        displayName: user.display_name,
        createdAt: user.created_at
      }
    });

  } catch (error) {
    console.error('Registration error:', error);
    res.status(500).json({
      error: 'Failed to create user'
    });
  }
});

// Login endpoint
router.post('/login', [
  body('email').isEmail().normalizeEmail(),
  body('password').notEmpty()
], async (req, res) => {
  try {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({
        error: 'Validation failed',
        details: errors.array()
      });
    }

    const { email, password } = req.body;
    const db = req.app.locals.db;

    // Find user
    const result = await db.query(
      'SELECT id, email, password_hash, display_name, created_at FROM users WHERE email = $1',
      [email]
    );

    if (result.rows.length === 0) {
      return res.status(401).json({
        error: 'Invalid email or password'
      });
    }

    const user = result.rows[0];

    // Verify password
    const isValidPassword = await bcrypt.compare(password, user.password_hash);
    
    if (!isValidPassword) {
      return res.status(401).json({
        error: 'Invalid email or password'
      });
    }

    // Generate JWT token
    const token = jwt.sign(
      { 
        userId: user.id, 
        email: user.email 
      },
      process.env.JWT_SECRET,
      { expiresIn: process.env.JWT_EXPIRES_IN }
    );

    res.json({
      message: 'Login successful',
      token,
      user: {
        id: user.id,
        email: user.email,
        displayName: user.display_name,
        createdAt: user.created_at
      }
    });

  } catch (error) {
    console.error('Login error:', error);
    res.status(500).json({
      error: 'Failed to login'
    });
  }
});

// Get current user endpoint
router.get('/me', authenticateToken, async (req, res) => {
  try {
    const db = req.app.locals.db;
    
    const result = await db.query(
      'SELECT id, email, display_name, created_at FROM users WHERE id = $1',
      [req.user.userId]
    );

    if (result.rows.length === 0) {
      return res.status(404).json({
        error: 'User not found'
      });
    }

    const user = result.rows[0];
    res.json({
      user: {
        id: user.id,
        email: user.email,
        displayName: user.display_name,
        createdAt: user.created_at
      }
    });

  } catch (error) {
    console.error('Get user error:', error);
    res.status(500).json({
      error: 'Failed to get user information'
    });
  }
});

// Update user profile endpoint
router.put('/profile', [
  authenticateToken,
  body('displayName').optional().isLength({ min: 1, max: 100 })
], async (req, res) => {
  try {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({
        error: 'Validation failed',
        details: errors.array()
      });
    }

    const { displayName } = req.body;
    const db = req.app.locals.db;

    const result = await db.query(
      `UPDATE users 
       SET display_name = $1 
       WHERE id = $2 
       RETURNING id, email, display_name, created_at`,
      [displayName, req.user.userId]
    );

    if (result.rows.length === 0) {
      return res.status(404).json({
        error: 'User not found'
      });
    }

    const user = result.rows[0];
    res.json({
      message: 'Profile updated successfully',
      user: {
        id: user.id,
        email: user.email,
        displayName: user.display_name,
        createdAt: user.created_at
      }
    });

  } catch (error) {
    console.error('Update profile error:', error);
    res.status(500).json({
      error: 'Failed to update profile'
    });
  }
});

module.exports = router;

// routes/habits.js (updated version)
const express = require('express');
const { body, validationResult, query } = require('express-validator');
const authenticateToken = require('../middleware/auth');
const router = express.Router();

// Apply authentication middleware to all routes
router.use(authenticateToken);

// Get all habits for authenticated user
router.get('/', async (req, res) => {
  try {
    const db = req.app.locals.db;
    
    const result = await db.query(
      `SELECT id, title, description, color, created_at, is_active 
       FROM habits 
       WHERE user_id = $1 AND is_active = true 
       ORDER BY created_at DESC`,
      [req.user.userId]
    );

    res.json({
      habits: result.rows
    });

  } catch (error) {
    console.error('Get habits error:', error);
    res.status(500).json({
      error: 'Failed to fetch habits'
    });
  }
});

// Create new habit
router.post('/', [
  body('title').notEmpty().isLength({ min: 1, max: 200 }),
  body('description').optional().isLength({ max: 1000 }),
  body('color').optional().matches(/^#[0-9A-Fa-f]{6}$/)
], async (req, res) => {
  try {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({
        error: 'Validation failed',
        details: errors.array()
      });
    }

    const { title, description, color } = req.body;
    const db = req.app.locals.db;

    const result = await db.query(
      `INSERT INTO habits (user_id, title, description, color) 
       VALUES ($1, $2, $3, $4) 
       RETURNING id, title, description, color, created_at, is_active`,
      [req.user.userId, title, description || '', color || '#4285f4']
    );

    const habit = result.rows[0];
    res.status(201).json({
      message: 'Habit created successfully',
      habit
    });

  } catch (error) {
    console.error('Create habit error:', error);
    res.status(500).json({
      error: 'Failed to create habit'
    });
  }
});

// Update habit
router.put('/:habitId', [
  body('title').optional().isLength({ min: 1, max: 200 }),
  body('description').optional().isLength({ max: 1000 }),
  body('color').optional().matches(/^#[0-9A-Fa-f]{6}$/),
  body('is_active').optional().isBoolean()
], async (req, res) => {
  try {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({
        error: 'Validation failed',
        details: errors.array()
      });
    }

    const { habitId } = req.params;
    const { title, description, color, is_active } = req.body;
    const db = req.app.locals.db;

    // Check if habit belongs to user
    const habitCheck = await db.query(
      'SELECT id FROM habits WHERE id = $1 AND user_id = $2',
      [habitId, req.user.userId]
    );

    if (habitCheck.rows.length === 0) {
      return res.status(404).json({
        error: 'Habit not found'
      });
    }

    // Build dynamic update query
    const updateFields = [];
    const updateValues = [];
    let paramIndex = 1;

    if (title !== undefined) {
      updateFields.push(`title = $${paramIndex}`);
      updateValues.push(title);
      paramIndex++;
    }
    if (description !== undefined) {
      updateFields.push(`description = $${paramIndex}`);
      updateValues.push(description);
      paramIndex++;
    }
    if (color !== undefined) {
      updateFields.push(`color = $${paramIndex}`);
      updateValues.push(color);
      paramIndex++;
    }
    if (is_active !== undefined) {
      updateFields.push(`is_active = $${paramIndex}`);
      updateValues.push(is_active);
      paramIndex++;
    }

    if (updateFields.length === 0) {
      return res.status(400).json({
        error: 'No fields to update'
      });
    }

    updateValues.push(habitId, req.user.userId);

    const result = await db.query(
      `UPDATE habits 
       SET ${updateFields.join(', ')} 
       WHERE id = $${paramIndex} AND user_id = $${paramIndex + 1}
       RETURNING id, title, description, color, created_at, is_active`,
      updateValues
    );

    const habit = result.rows[0];
    res.json({
      message: 'Habit updated successfully',
      habit
    });

  } catch (error) {
    console.error('Update habit error:', error);
    res.status(500).json({
      error: 'Failed to update habit'
    });
  }
});

// Delete habit
router.delete('/:habitId', async (req, res) => {
  try {
    const { habitId } = req.params;
    const db = req.app.locals.db;

    // Check if habit belongs to user
    const habitCheck = await db.query(
      'SELECT id FROM habits WHERE id = $1 AND user_id = $2',
      [habitId, req.user.userId]
    );

    if (habitCheck.rows.length === 0) {
      return res.status(404).json({
        error: 'Habit not found'
      });
    }

    // Soft delete by setting is_active to false
    await db.query(
      'UPDATE habits SET is_active = false WHERE id = $1 AND user_id = $2',
      [habitId, req.user.userId]
    );

    res.json({
      message: 'Habit deleted successfully'
    });

  } catch (error) {
    console.error('Delete habit error:', error);
    res.status(500).json({
      error: 'Failed to delete habit'
    });
  }
});

// Mark habit as completed for a specific date
router.post('/:habitId/complete', [
  body('date').isISO8601().toDate()
], async (req, res) => {
  try {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({
        error: 'Validation failed',
        details: errors.array()
      });
    }

    const { habitId } = req.params;
    const { date } = req.body;
    const db = req.app.locals.db;

    // Check if habit belongs to user
    const habitCheck = await db.query(
      'SELECT id FROM habits WHERE id = $1 AND user_id = $2 AND is_active = true',
      [habitId, req.user.userId]
    );

    if (habitCheck.rows.length === 0) {
      return res.status(404).json({
        error: 'Habit not found'
      });
    }

    // Format date to ensure it's just the date part
    const completionDate = new Date(date).toISOString().split('T')[0];

    // Insert or update completion
    const result = await db.query(
      `INSERT INTO habit_completions (user_id, habit_id, completion_date)
       VALUES ($1, $2, $3)
       ON CONFLICT (user_id, habit_id, completion_date) 
       DO NOTHING
       RETURNING id, completion_date`,
      [req.user.userId, habitId, completionDate]
    );

    if (result.rows.length > 0) {
      res.json({
        message: 'Habit marked as completed',
        completion: result.rows[0]
      });
    } else {
      res.json({
        message: 'Habit already completed for this date'
      });
    }

  } catch (error) {
    console.error('Complete habit error:', error);
    res.status(500).json({
      error: 'Failed to mark habit as completed'
    });
  }
});

// Remove habit completion for a specific date
router.delete('/:habitId/complete', [
  body('date').isISO8601().toDate()
], async (req, res) => {
  try {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({
        error: 'Validation failed',
        details: errors.array()
      });
    }

    const { habitId } = req.params;
    const { date } = req.body;
    const db = req.app.locals.db;

    // Format date
    const completionDate = new Date(date).toISOString().split('T')[0];

    const result = await db.query(
      `DELETE FROM habit_completions 
       WHERE user_id = $1 AND habit_id = $2 AND completion_date = $3
       RETURNING id`,
      [req.user.userId, habitId, completionDate]
    );

    if (result.rows.length > 0) {
      res.json({
        message: 'Habit completion removed'
      });
    } else {
      res.status(404).json({
        error: 'No completion found for this date'
      });
    }

  } catch (error) {
    console.error('Remove completion error:', error);
    res.status(500).json({
      error: 'Failed to remove habit completion'
    });
  }
});

// Get completions for a habit within a date range
router.get('/:habitId/completions', [
  query('startDate').optional().isISO8601().toDate(),
  query('endDate').optional().isISO8601().toDate()
], async (req, res) => {
  try {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({
        error: 'Validation failed',
        details: errors.array()
      });
    }

    const { habitId } = req.params;
    const { startDate, endDate } = req.query;
    const db = req.app.locals.db;

    // Default to current year if no date range provided
    const start = startDate ? new Date(startDate) : new Date(new Date().getFullYear(), 0, 1);
    const end = endDate ? new Date(endDate) : new Date();

    const result = await db.query(
      `SELECT completion_date, created_at
       FROM habit_completions
       WHERE user_id = $1 AND habit_id = $2 
       AND completion_date BETWEEN $3 AND $4
       ORDER BY completion_date`,
      [req.user.userId, habitId, start.toISOString().split('T')[0], end.toISOString().split('T')[0]]
    );

    res.json({
      completions: result.rows
    });

  } catch (error) {
    console.error('Get completions error:', error);
    res.status(500).json({
      error: 'Failed to fetch completions'
    });
  }
});

// Get all completions for user (for heatmap)
router.get('/completions/all', [
  query('startDate').optional().isISO8601().toDate(),
  query('endDate').optional().isISO8601().toDate()
], async (req, res) => {
  try {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({
        error: 'Validation failed',
        details: errors.array()
      });
    }

    const { startDate, endDate } = req.query;
    const db = req.app.locals.db;

    // Default to current year if no date range provided
    const start = startDate ? new Date(startDate) : new Date(new Date().getFullYear(), 0, 1);
    const end = endDate ? new Date(endDate) : new Date();

    const result = await db.query(
      `SELECT 
         hc.completion_date,
         COUNT(*) as completion_count,
         ARRAY_AGG(h.title) as habit_titles
       FROM habit_completions hc
       JOIN habits h ON hc.habit_id = h.id
       WHERE hc.user_id = $1 
       AND hc.completion_date BETWEEN $2 AND $3
       AND h.is_active = true
       GROUP BY hc.completion_date
       ORDER BY hc.completion_date`,
      [req.user.userId, start.toISOString().split('T')[0], end.toISOString().split('T')[0]]
    );

    res.json({
      completions: result.rows
    });

  } catch (error) {
    console.error('Get all completions error:', error);
    res.status(500).json({
      error: 'Failed to fetch completions'
    });
  }
});

// Get habit statistics
router.get('/stats', async (req, res) => {
  try {
    const db = req.app.locals.db;
    
    // Get total habits
    const habitsResult = await db.query(
      'SELECT COUNT(*) as total_habits FROM habits WHERE user_id = $1 AND is_active = true',
      [req.user.userId]
    );

    // Get total completions
    const completionsResult = await db.query(
      'SELECT COUNT(*) as total_completions FROM habit_completions WHERE user_id = $1',
      [req.user.userId]
    );

    // Get current streak (consecutive days with at least one completion)
    const streakResult = await db.query(
      `WITH daily_completions AS (
         SELECT completion_date
         FROM habit_completions
         WHERE user_id = $1
         GROUP BY completion_date
         ORDER BY completion_date DESC
       ),
       date_series AS (
         SELECT generate_series(
           CURRENT_DATE - INTERVAL '365 days',
           CURRENT_DATE,
           '1 day'::interval
         )::date as date
       ),
       streak_data AS (
         SELECT 
           ds.date,
           CASE WHEN dc.completion_date IS NOT NULL THEN 1 ELSE 0 END as has_completion
         FROM date_series ds
         LEFT JOIN daily_completions dc ON ds.date = dc.completion_date
         ORDER BY ds.date DESC
       )
       SELECT COUNT(*) as current_streak
       FROM (
         SELECT 
           date,
           has_completion,
           ROW_NUMBER() OVER (ORDER BY date DESC) as rn
         FROM streak_data
       ) ranked
       WHERE has_completion = 1 AND rn <= (
         SELECT COALESCE(MIN(rn), 0)
         FROM (
           SELECT ROW_NUMBER() OVER (ORDER BY date DESC) as rn
           FROM streak_data
           WHERE has_completion = 0
         ) first_gap
       )`,
      [req.user.userId]
    );

    // Get this week's completions
    const thisWeekResult = await db.query(
      `SELECT COUNT(*) as week_completions
       FROM habit_completions
       WHERE user_id = $1 
       AND completion_date >= date_trunc('week', CURRENT_DATE)`,
      [req.user.userId]
    );

    res.json({
      stats: {
        totalHabits: parseInt(habitsResult.rows[0].total_habits),
        totalCompletions: parseInt(completionsResult.rows[0].total_completions),
        currentStreak: parseInt(streakResult.rows[0]?.current_streak || 0),
        weekCompletions: parseInt(thisWeekResult.rows[0].week_completions)
      }
    });

  } catch (error) {
    console.error('Get stats error:', error);
    res.status(500).json({
      error: 'Failed to fetch statistics'
    });
  }
});

// Get habit details with recent completions
router.get('/:habitId', async (req, res) => {
  try {
    const { habitId } = req.params;
    const db = req.app.locals.db;

    // Get habit details
    const habitResult = await db.query(
      `SELECT id, title, description, color, created_at, is_active
       FROM habits 
       WHERE id = $1 AND user_id = $2`,
      [habitId, req.user.userId]
    );

    if (habitResult.rows.length === 0) {
      return res.status(404).json({
        error: 'Habit not found'
      });
    }

    // Get recent completions (last 30 days)
    const completionsResult = await db.query(
      `SELECT completion_date, created_at
       FROM habit_completions
       WHERE user_id = $1 AND habit_id = $2
       AND completion_date >= CURRENT_DATE - INTERVAL '30 days'
       ORDER BY completion_date DESC`,
      [req.user.userId, habitId]
    );

    const habit = habitResult.rows[0];
    res.json({
      habit: {
        ...habit,
        recentCompletions: completionsResult.rows
      }
    });

  } catch (error) {
    console.error('Get habit details error:', error);
    res.status(500).json({
      error: 'Failed to fetch habit details'
    });
  }
});

module.exports = router;