import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/user_profile.dart';

Future<UserProfile> loadSupabaseUserProfile(String userId) async {
  final response = await Supabase.instance.client
      .from('profiles')
      .select()
      .eq('id', userId)
      .single();

  return UserProfile.fromJson(response);
}
