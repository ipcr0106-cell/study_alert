/**
 * 세션 start_time(UTC)을 기준으로 한국(Asia/Seoul) 달력 날짜 문자열 YYYY-MM-DD
 */
export function toKoreaDateString(isoOrDate) {
  const d = typeof isoOrDate === 'string' ? new Date(isoOrDate) : isoOrDate;
  return new Intl.DateTimeFormat('en-CA', {
    timeZone: 'Asia/Seoul',
    year: 'numeric',
    month: '2-digit',
    day: '2-digit',
  }).format(d);
}

/** 한국 시각 기준 오늘 0시 (UTC로 표현된 Instant) */
export function startOfKoreaToday() {
  const parts = new Intl.DateTimeFormat('en-CA', {
    timeZone: 'Asia/Seoul',
    year: 'numeric',
    month: '2-digit',
    day: '2-digit',
  }).formatToParts(new Date());
  const y = parts.find((p) => p.type === 'year').value;
  const m = parts.find((p) => p.type === 'month').value;
  const day = parts.find((p) => p.type === 'day').value;
  return new Date(`${y}-${m}-${day}T00:00:00+09:00`);
}

export function addKoreaDays(baseStart, days) {
  return new Date(baseStart.getTime() + days * 86400000);
}
