import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseService {
  final SupabaseClient _client = Supabase.instance.client;

  Future<List<String>> getGroups() async {
    try {
      final response = await _client
          .from('groups')
          .select('group_name')
          .order('group_name', ascending: true);
      return response.map((item) => item['group_name'] as String).toList();
    } catch (e) {
      throw Exception('Failed to load groups: $e');
    }
  }
}