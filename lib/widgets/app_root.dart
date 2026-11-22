import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stadtschreiber/provider/supabase_session_state_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../screens/login_screen.dart';
import '../screens/home_screen.dart';

class AppRoot extends ConsumerWidget {
  const AppRoot({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authAsync = ref.watch(supabaseSessionStateProvider);

    return authAsync.when(
      data: (session) {
        if (session == null) {
          return const LoginScreen();
        } else {
          return const MyHomePage(title: "Stadtschreiber");
        }
      },
      loading: () {
        final restoredSession = Supabase.instance.client.auth.currentSession;

        if (restoredSession == null) {
          return const LoginScreen();
        }

        return const MyHomePage(title: 'Stadtschreiber');
      },
      error: (e, st) => Center(child: Text('Auth-Error: $e')),
    );
  }
}
