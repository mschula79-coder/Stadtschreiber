import 'package:supabase_flutter/supabase_flutter.dart';

class UserRepository {
  final SupabaseClient supabase;

  UserRepository(this.supabase);

  Future<void> updateEmail(String newEmail) async {
    await supabase.auth.updateUser(
      UserAttributes(email: newEmail),
    );
  }

  Future<void> updateUsername(String newName) async {
    final user = supabase.auth.currentUser;
    if (user == null) return;

    await supabase
        .from('profiles')
        .update({'username': newName})
        .eq('id', user.id);
  }

  Future<Map<String, dynamic>> fetchProfile() async {
    final user = supabase.auth.currentUser;
    if (user == null) throw Exception("No user logged in");

    final data = await supabase
        .from('profiles')
        .select()
        .eq('id', user.id)
        .single();

    return data;
  }
}
