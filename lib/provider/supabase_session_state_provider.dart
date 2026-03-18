import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

//  
final supabaseSessionStateProvider = StreamProvider<Session?>((ref) {
/*   final session = Supabase.instance.client.auth.currentSession;
 */
  return Supabase.instance.client.auth.onAuthStateChange.map(
    (event) => event.session,
  );
});
