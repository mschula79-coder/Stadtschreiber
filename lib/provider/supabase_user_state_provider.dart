import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stadtschreiber/provider/supabase_user_profile_provider.dart';

class SupabaseUserState {
  final String username;
  final bool isAdmin;
  final bool loading;
  final String userid;

  SupabaseUserState({
    required this.username,
    required this.isAdmin,
    required this.loading,
    required this.userid
  });
}

/// DIESEN PROVIDER IM UI NUTZEN
final supabaseUserStateProvider = Provider<SupabaseUserState>((ref) {
  final profileAsync = ref.watch(supabaseUserProfileLoaderProvider);

  return profileAsync.when(
    data: (profile) => SupabaseUserState(
      username: profile?.username ?? '',
      userid: profile?.id ?? '',
      isAdmin: profile?.isAdmin ?? false,
      loading: false,
    ),
    loading: () => SupabaseUserState(
      username: '',
      userid: '',
      isAdmin: false,
      loading: true,
    ),
    error: (_, _) => SupabaseUserState(
      username: '',
      userid: '',
      isAdmin: false,
      loading: false,
    ),
  );
});
