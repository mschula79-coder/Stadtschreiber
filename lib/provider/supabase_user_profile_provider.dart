import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stadtschreiber/models/user_profile.dart';
import 'package:stadtschreiber/provider/supabase_session_state_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// DO NOT USE IN UI, loads the profile from Supabase
final supabaseUserProfileLoaderProvider = FutureProvider<UserProfile?>((ref) async {
  final session = ref.watch(supabaseSessionStateProvider).value;
  if (session == null) return null;

  final response = await Supabase.instance.client
      .from('profiles')
      .select()
      .eq('id', session.user.id)
      .single();

  return UserProfile.fromJson(response);
});
