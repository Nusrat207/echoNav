import 'package:supabase_flutter/supabase_flutter.dart';

class DatabaseService {
  final SupabaseClient _supabase = Supabase.instance.client;

  Future<bool> isUserExists(String faceId) async {
    try {
      print("Checking if user exists for Face ID: $faceId");

      // Query the 'users' table for the faceId
      final response = await _supabase
          .from('users')
          .select()
          .eq('faceId', faceId)
          .single();

      print("User exists: ${response != null}");
      return response != null;
    } catch (e) {
      print("Error checking if user exists: $e");
      return false;
    }
  }

  Future<void> addUser(String faceId) async {
    try {
      print("Adding new user with Face ID: $faceId");

      // Insert a new user into the 'users' table
      await _supabase.from('users').insert({
        'faceId': faceId,
        'createdAt': DateTime.now().toIso8601String(),
      });

      print("User added successfully");
    } catch (e) {
      print("Error adding user: $e");
    }
  }
}