import express from 'express';
import { getSubjects, createSubject, deleteSubject } from '../services/subjectService.js';

const router = express.Router();

// GET /subjects/:userId
router.get('/:userId', async (req, res) => {
  try {
    const { userId } = req.params;
    if (!userId) return res.status(400).json({ message: 'userId는 필수입니다.' });
    const subjects = await getSubjects({ userId });
    return res.json({ subjects });
  } catch (err) {
    console.error(err);
    return res.status(500).json({ message: err.message });
  }
});

// POST /subjects
router.post('/', async (req, res) => {
  try {
    const { userId, name, color } = req.body;
    if (!userId || !name) return res.status(400).json({ message: 'userId, name은 필수입니다.' });
    const subject = await createSubject({ userId, name, color });
    return res.json({ subject });
  } catch (err) {
    console.error(err);
    return res.status(500).json({ message: err.message });
  }
});

// DELETE /subjects/:id
router.delete('/:id', async (req, res) => {
  try {
    const { id } = req.params;
    const { userId } = req.body;
    if (!userId) return res.status(400).json({ message: 'userId는 필수입니다.' });
    await deleteSubject({ id: parseInt(id), userId });
    return res.json({ success: true });
  } catch (err) {
    console.error(err);
    return res.status(500).json({ message: err.message });
  }
});

export default router;
