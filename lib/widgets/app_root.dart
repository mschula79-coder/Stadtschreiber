import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stadtschreiber/provider/supabase_session_state_provider.dart';

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
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, st) => Center(child: Text('Auth-Fehler: $e')),
    );
  }
}

