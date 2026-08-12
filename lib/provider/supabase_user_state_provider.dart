import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'supabase_user_profile_provider.dart';

class SupabaseUserState {
  final String userid;
  final String username;
  final bool isAdmin;
  final bool isAuthor;
  final bool loading;

  SupabaseUserState({
    required this.userid,
    required this.username,
    required this.isAdmin,
    required this.isAuthor,
    required this.loading,
  });

  factory SupabaseUserState.loadingState() => SupabaseUserState(
        userid: '',
        username: '',
        isAdmin: false,
        isAuthor: false,
        loading: true,
      );

  factory SupabaseUserState.loggedOut() => SupabaseUserState(
        userid: '',
        username: '',
        isAdmin: false,
        isAuthor: false,
        loading: false,
      );
}

final supabaseUserStateProvider =
    NotifierProvider<SupabaseUserStateNotifier, SupabaseUserState>(
  SupabaseUserStateNotifier.new,
);

class SupabaseUserStateNotifier extends Notifier<SupabaseUserState> {
  @override
  SupabaseUserState build() {
    final auth = Supabase.instance.client.auth;

    state = SupabaseUserState.loadingState();

    final session = auth.currentSession;
    if (session?.user != null) {
      _loadProfile(session!.user.id);
    } else {
      state = SupabaseUserState.loggedOut();
    }

    auth.onAuthStateChange.listen((data) {
      final event = data.event;
      final session = data.session;

      if (event == AuthChangeEvent.signedIn && session?.user != null) {
        _loadProfile(session!.user.id);
      }

      if (event == AuthChangeEvent.signedOut) {
        state = SupabaseUserState.loggedOut();
      }
    });

    return state;
  }

  Future<void> _loadProfile(String userId) async {
    final profileAsync =
        await ref.read(supabaseUserProfileLoaderProvider.future);

    state = SupabaseUserState(
      userid: userId,
      username: profileAsync?.username ?? '',
      isAdmin: profileAsync?.isAdmin ?? false,
      isAuthor: profileAsync?.isAuthor ?? false,
      loading: false,
    );
  }
}
