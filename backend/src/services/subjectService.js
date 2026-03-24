import { supabase } from '../supabaseClient.js';

const TABLE = 'subjects';

export async function getSubjects({ userId }) {
  const { data, error } = await supabase
    .from(TABLE)
    .select('id, name, color, created_at')
    .eq('user_id', userId)
    .order('created_at', { ascending: true });

  if (error) throw new Error(`과목 조회 오류: ${error.message}`);
  return data || [];
}

export async function createSubject({ userId, name, color }) {
  const { data, error } = await supabase
    .from(TABLE)
    .insert({ user_id: userId, name: name.trim(), color: color || '#6366F1' })
    .select()
    .single();

  if (error) throw new Error(`과목 생성 오류: ${error.message}`);
  return data;
}

export async function deleteSubject({ id, userId }) {
  const { error } = await supabase
    .from(TABLE)
    .delete()
    .eq('id', id)
    .eq('user_id', userId);

  if (error) throw new Error(`과목 삭제 오류: ${error.message}`);
}
