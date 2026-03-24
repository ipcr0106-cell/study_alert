import express from 'express';
import {
  createSession,
  updateSession,
  endSession,
  getTodayStats,
  getTodaySubjectStats,
  getCalendarRecords,
  getWeeklyStats,
  getMonthlyStats,
} from '../services/sessionService.js';

const router = express.Router();

router.post('/start', async (req, res) => {
  try {
    const { userId, startTime, subjectId } = req.body;
    if (!userId) return res.status(400).json({ message: 'userId는 필수입니다.' });

    const now = startTime ? new Date(startTime) : new Date();
    const session = await createSession({
      userId,
      startTime: now.toISOString(),
      subjectId: subjectId ? parseInt(subjectId) : null,
    });
    return res.json({ sessionId: session.id, startTime: session.start_time });
  } catch (err) {
    console.error(err);
    return res.status(500).json({ message: err.message });
  }
});

router.post('/update', async (req, res) => {
  try {
    const { sessionId, focusTime, distractionCount } = req.body;
    if (!sessionId) return res.status(400).json({ message: 'sessionId는 필수입니다.' });

    const safeFocusTime = typeof focusTime === 'number' && focusTime >= 0 ? focusTime : 0;
    const safeDistractionCount = typeof distractionCount === 'number' && distractionCount >= 0 ? distractionCount : 0;

    const session = await updateSession({ sessionId, focusTime: safeFocusTime, distractionCount: safeDistractionCount });
    return res.json({ sessionId: session.id, focusTime: session.focus_time, distractionCount: session.distraction_count });
  } catch (err) {
    console.error(err);
    return res.status(500).json({ message: err.message });
  }
});

router.post('/end', async (req, res) => {
  try {
    const { sessionId, endTime, focusTime, distractionCount } = req.body;
    if (!sessionId) return res.status(400).json({ message: 'sessionId는 필수입니다.' });

    const now = endTime ? new Date(endTime) : new Date();
    const safeFocusTime = typeof focusTime === 'number' && focusTime >= 0 ? focusTime : 0;
    const safeDistractionCount = typeof distractionCount === 'number' && distractionCount >= 0 ? distractionCount : 0;

    const session = await endSession({ sessionId, endTime: now.toISOString(), focusTime: safeFocusTime, distractionCount: safeDistractionCount });
    return res.json({
      sessionId: session.id,
      startTime: session.start_time,
      endTime: session.end_time,
      focusTime: session.focus_time,
      distractionCount: session.distraction_count,
    });
  } catch (err) {
    console.error(err);
    return res.status(500).json({ message: err.message });
  }
});

router.get('/today/:userId', async (req, res) => {
  try {
    const { userId } = req.params;
    if (!userId) return res.status(400).json({ message: 'userId는 필수입니다.' });
    const stats = await getTodayStats({ userId });
    return res.json(stats);
  } catch (err) {
    console.error(err);
    return res.status(500).json({ message: err.message });
  }
});

// 오늘 과목별 집중 시간
router.get('/today-subjects/:userId', async (req, res) => {
  try {
    const { userId } = req.params;
    if (!userId) return res.status(400).json({ message: 'userId는 필수입니다.' });
    const subjects = await getTodaySubjectStats({ userId });
    return res.json({ subjects });
  } catch (err) {
    console.error(err);
    return res.status(500).json({ message: err.message });
  }
});

// 캘린더 기록 (월별)
router.get('/calendar/:userId', async (req, res) => {
  try {
    const { userId } = req.params;
    const year  = parseInt(req.query.year)  || new Date().getFullYear();
    const month = parseInt(req.query.month) || new Date().getMonth() + 1;
    const records = await getCalendarRecords({ userId, year, month });
    return res.json({ records });
  } catch (err) {
    console.error(err);
    return res.status(500).json({ message: err.message });
  }
});

// 주간 통계 (최근 7일)
router.get('/weekly/:userId', async (req, res) => {
  try {
    const { userId } = req.params;
    const days = await getWeeklyStats({ userId });
    return res.json({ days });
  } catch (err) {
    console.error(err);
    return res.status(500).json({ message: err.message });
  }
});

// 월간 통계 (최근 30일)
router.get('/monthly/:userId', async (req, res) => {
  try {
    const { userId } = req.params;
    const days = await getMonthlyStats({ userId });
    return res.json({ days });
  } catch (err) {
    console.error(err);
    return res.status(500).json({ message: err.message });
  }
});

export default router;
