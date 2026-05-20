import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';

const String supabaseUrl = 'https://mpdpbfaorquuqvhawwea.supabase.co';
const String supabaseAnonKey =
    'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im1wZHBiZmFvcnF1dXF2aGF3d2VhIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzQ5MTkwMTAsImV4cCI6MjA5MDQ5NTAxMH0.MjqWGPBgWkRusMoRu_m47uZveVbKHXuCdQpBwx0Rmkk';

SupabaseClient get supabase => Supabase.instance.client;

// ─── Auth ────────────────────────────────────────────────────────────────────

Future<AuthResponse> signIn(String email, String password) async {
  return supabase.auth.signInWithPassword(email: email, password: password);
}

Future<AuthResponse> signUp(String email, String password) async {
  return supabase.auth.signUp(email: email, password: password);
}

Future<void> signOut() async {
  await supabase.auth.signOut();
}

User? get currentUser => supabase.auth.currentUser;

// ─── Profile ─────────────────────────────────────────────────────────────────

Future<Map<String, dynamic>?> getProfile() async {
  final user = currentUser;
  if (user == null) return null;
  final data = await supabase
      .from('profiles')
      .select()
      .eq('auth_uid', user.id)
      .maybeSingle();
  return data;
}

Future<Map<String, dynamic>> upsertProfile(Map<String, dynamic> data) async {
  final user = currentUser;
  if (user == null) throw Exception('Not authenticated');

  // Check if profile exists
  final existing = await supabase
      .from('profiles')
      .select('id')
      .eq('auth_uid', user.id)
      .maybeSingle();

  if (existing != null) {
    final updated = await supabase
        .from('profiles')
        .update(data)
        .eq('auth_uid', user.id)
        .select()
        .single();
    return updated;
  } else {
    final inserted = await supabase
        .from('profiles')
        .insert({
          ...data,
          'auth_uid': user.id,
          if (user.email != null) 'email': user.email,
        })
        .select()
        .single();
    return inserted;
  }
}

// ─── Measurements ────────────────────────────────────────────────────────────

Future<List<Map<String, dynamic>>> getMeasurements(String profileId) async {
  final data = await supabase
      .from('measurements')
      .select()
      .eq('patient_id', profileId)
      .order('measurement_date', ascending: false);
  return List<Map<String, dynamic>>.from(data);
}

Future<Map<String, dynamic>> addMeasurement(
    Map<String, dynamic> data) async {
  final inserted = await supabase
      .from('measurements')
      .insert(data)
      .select()
      .single();
  return inserted;
}

Future<void> updateMeasurement(
    String id, Map<String, dynamic> data) async {
  await supabase.from('measurements').update(data).eq('id', id);
}

Future<void> deleteMeasurement(String id) async {
  await supabase.from('measurements').delete().eq('id', id);
}

// ─── Storage ──────────────────────────────────────────────────────────────────

Future<String> uploadPhoto(File file, String profileId) async {
  final fileName =
      '$profileId/${DateTime.now().millisecondsSinceEpoch}.jpg';
  await supabase.storage
      .from('patient-photos')
      .upload(fileName, file, fileOptions: const FileOptions(upsert: true));
  return supabase.storage.from('patient-photos').getPublicUrl(fileName);
}

// ─── Calendar Events ─────────────────────────────────────────────────────────

Future<List<Map<String, dynamic>>> getCalendarEvents(
    String profileId) async {
  final data = await supabase
      .from('calendar_events')
      .select()
      .eq('patient_id', profileId)
      .order('event_date', ascending: true);
  return List<Map<String, dynamic>>.from(data);
}

Future<Map<String, dynamic>> addCalendarEvent(
    Map<String, dynamic> data) async {
  final inserted = await supabase
      .from('calendar_events')
      .insert(data)
      .select()
      .single();
  return inserted;
}

Future<void> updateCalendarEvent(
    String id, Map<String, dynamic> data) async {
  await supabase.from('calendar_events').update(data).eq('id', id);
}

Future<void> deleteCalendarEvent(String id) async {
  await supabase.from('calendar_events').delete().eq('id', id);
}

// ─── Tips & Suggestions ──────────────────────────────────────────────────────

Future<List<Map<String, dynamic>>> getTips() async {
  final data = await supabase
      .from('tips')
      .select()
      .eq('is_published', true)
      .order('published_at', ascending: false);
  return List<Map<String, dynamic>>.from(data);
}
