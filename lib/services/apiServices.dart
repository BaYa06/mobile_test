import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/schedule.dart';

class ApiService {
  final SupabaseClient _client = Supabase.instance.client;

  Future<List<Schedule>> getSchedule(String groupName, [String? day]) async {
    try {
      var query = _client
          .from('schedule')
          .select()
          .eq('group_name', groupName);
      if (day != null) {
        query = query.eq('day', day);
      }
      final response = await query;
      return response.map((json) => Schedule.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Failed to load schedule: $e');
    }
  }
}