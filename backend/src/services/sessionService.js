import { supabase } from '../supabaseClient.js';
import {
  addKoreaDays,
  startOfKoreaToday,
  toKoreaDateString,
} from '../utils/koreaTime.js';

const TABLE_NAME = 'sessions';

export async function createSession({ userId, startTime, subjectId }) {
  const { data, error } = await supabase
    .from(TABLE_NAME)
    .insert({
      user_id: userId,
      start_time: startTime,
      end_time: null,
      focus_time: 0,
      distraction_count: 0,
      ...(subjectId ? { subject_id: subjectId } : {}),
    })
    .select()
    .single();

  if (error) throw new Error(`세션 생성 중 오류: ${error.message}`);
  return data;
}

export async function updateSession({ sessionId, focusTime, distractionCount }) {
  const { data, error } = await supabase
    .from(TABLE_NAME)
    .update({ focus_time: focusTime, distraction_count: distractionCount })
    .eq('id', sessionId)
    .select()
    .single();

  if (error) throw new Error(`세션 업데이트 중 오류: ${error.message}`);
  return data;
}

export async function endSession({ sessionId, endTime, focusTime, distractionCount }) {
  const { data, error } = await supabase
    .from(TABLE_NAME)
    .update({ end_time: endTime, focus_time: focusTime, distraction_count: distractionCount })
    .eq('id', sessionId)
    .select()
    .single();

  if (error) throw new Error(`세션 종료 중 오류: ${error.message}`);
  return data;
}

// ── 오늘 통계 (전체) — Asia/Seoul 달력 기준 ───────────────────────────────────
export async function getTodayStats({ userId }) {
  const todayStart = startOfKoreaToday();
  const tomorrowStart = addKoreaDays(todayStart, 1);

  const { data, error } = await supabase
    .from(TABLE_NAME)
    .select('focus_time, distraction_count')
    .eq('user_id', userId)
    .gte('start_time', todayStart.toISOString())
    .lt('start_time', tomorrowStart.toISOString());

  if (error) throw new Error(`오늘 통계 조회 중 오류: ${error.message}`);

  const totalFocusTime = (data || []).reduce((s, r) => s + (r.focus_time || 0), 0);
  const totalDistractionCount = (data || []).reduce((s, r) => s + (r.distraction_count || 0), 0);
  const sessionCount = (data || []).length;
  return { totalFocusTime, totalDistractionCount, sessionCount };
}

// ── 오늘 과목별 집중 시간 — Asia/Seoul 달력 기준 ───────────────────────────────
export async function getTodaySubjectStats({ userId }) {
  const todayStart = startOfKoreaToday();
  const tomorrowStart = addKoreaDays(todayStart, 1);

  const { data, error } = await supabase
    .from(TABLE_NAME)
    .select('focus_time, subject_id, subjects(name, color)')
    .eq('user_id', userId)
    .gte('start_time', todayStart.toISOString())
    .lt('start_time', tomorrowStart.toISOString());

  if (error) throw new Error(`과목별 오늘 통계 조회 오류: ${error.message}`);

  const map = {};
  for (const row of (data || [])) {
    const key = row.subject_id ?? 'none';
    if (!map[key]) {
      map[key] = {
        subjectId: row.subject_id,
        subjectName: row.subjects?.name ?? '기타',
        color: row.subjects?.color ?? '#9CA3AF',
        focusTime: 0,
      };
    }
    map[key].focusTime += row.focus_time || 0;
  }
  return Object.values(map);
}

// ── 캘린더용: 날짜별 기록 (해당 월, 한국 자정 경계) ───────────────────────────
export async function getCalendarRecords({ userId, year, month }) {
  const sm = String(month).padStart(2, '0');
  const from = new Date(`${year}-${sm}-01T00:00:00+09:00`);
  const to =
    month === 12
      ? new Date(`${year + 1}-01-01T00:00:00+09:00`)
      : new Date(`${year}-${String(month + 1).padStart(2, '0')}-01T00:00:00+09:00`);

  const { data, error } = await supabase
    .from(TABLE_NAME)
    .select('start_time, focus_time, distraction_count, subject_id, subjects(name, color)')
    .eq('user_id', userId)
    .gte('start_time', from.toISOString())
    .lt('start_time', to.toISOString())
    .order('start_time', { ascending: true });

  if (error) throw new Error(`캘린더 기록 조회 오류: ${error.message}`);

  // 날짜별로 집계 (한국 날짜)
  const dayMap = {};
  for (const row of (data || [])) {
    const date = toKoreaDateString(row.start_time);
    if (!dayMap[date]) {
      dayMap[date] = { date, totalFocusTime: 0, distractionCount: 0, subjects: {} };
    }
    dayMap[date].totalFocusTime += row.focus_time || 0;
    dayMap[date].distractionCount += row.distraction_count || 0;

    const subName = row.subjects?.name ?? '기타';
    const color   = row.subjects?.color ?? '#9CA3AF';
    if (!dayMap[date].subjects[subName]) {
      dayMap[date].subjects[subName] = { name: subName, color, focusTime: 0 };
    }
    dayMap[date].subjects[subName].focusTime += row.focus_time || 0;
  }

  return Object.values(dayMap).map(d => ({
    ...d,
    subjects: Object.values(d.subjects),
  }));
}

// ── 주간 통계 (최근 7일, 한국 달력) ────────────────────────────────────────────
export async function getWeeklyStats({ userId }) {
  const todayKoreaStart = startOfKoreaToday();
  const from = addKoreaDays(todayKoreaStart, -6);
  const toExclusive = addKoreaDays(todayKoreaStart, 1);

  const labelKeys = [];
  for (let i = 0; i < 7; i++) {
    labelKeys.push(toKoreaDateString(addKoreaDays(from, i)));
  }

  const { data, error } = await supabase
    .from(TABLE_NAME)
    .select('start_time, focus_time, distraction_count')
    .eq('user_id', userId)
    .gte('start_time', from.toISOString())
    .lt('start_time', toExclusive.toISOString());

  if (error) throw new Error(`주간 통계 조회 오류: ${error.message}`);

  const dayMap = {};
  for (const key of labelKeys) {
    dayMap[key] = { date: key, focusTime: 0, distractionCount: 0 };
  }
  for (const row of (data || [])) {
    const date = toKoreaDateString(row.start_time);
    if (dayMap[date]) {
      dayMap[date].focusTime += row.focus_time || 0;
      dayMap[date].distractionCount += row.distraction_count || 0;
    }
  }
  return labelKeys.map((k) => dayMap[k]);
}

// ── 월간 통계 (최근 30일, 한국 달력) ─────────────────────────────────────────
export async function getMonthlyStats({ userId }) {
  const todayKoreaStart = startOfKoreaToday();
  const from = addKoreaDays(todayKoreaStart, -29);

  const { data, error } = await supabase
    .from(TABLE_NAME)
    .select('start_time, focus_time, distraction_count')
    .eq('user_id', userId)
    .gte('start_time', from.toISOString());

  if (error) throw new Error(`월간 통계 조회 오류: ${error.message}`);

  const dayMap = {};
  for (const row of (data || [])) {
    const date = toKoreaDateString(row.start_time);
    if (!dayMap[date]) dayMap[date] = { date, focusTime: 0, distractionCount: 0 };
    dayMap[date].focusTime += row.focus_time || 0;
    dayMap[date].distractionCount += row.distraction_count || 0;
  }
  return Object.values(dayMap).sort((a, b) => a.date.localeCompare(b.date));
}
