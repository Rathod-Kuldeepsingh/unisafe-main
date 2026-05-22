import 'package:supabase/supabase.dart';

void main() async {
  final client = SupabaseClient(
    'https://jwsibafhwkujlpgzqaph.supabase.co',
    'sb_publishable_Ann0sNjsSu8QeM9KVGo72Q_g1gz9pvv',
    authOptions: const AuthClientOptions(authFlowType: AuthFlowType.implicit),
  );

  final email = 'testadmin_${DateTime.now().millisecondsSinceEpoch}@example.com';
  final password = 'password123';

  print("1. Signing up a test admin user: $email");
  try {
    final authRes = await client.auth.signUp(
      email: email,
      password: password,
      data: {'role': 'admin', 'name': 'Test Admin'},
    );
    print("Sign up succeeded: ${authRes.user?.email}, Role: ${authRes.user?.userMetadata?['role']}");
  } catch (e) {
    print("Sign up failed: $e");
    return;
  }

  print("\n2. Inserting a test report as the authenticated admin...");
  int? reportId;
  try {
    final insertRes = await client.from('incident_reports').insert({
      'title': 'Test Admin Update',
      'description': 'Testing update by admin',
      'location': 'Test Admin Location',
      'status': 'Pending',
    }).select();
    
    if (insertRes.isNotEmpty) {
      reportId = insertRes.first['id'];
      print("Inserted test report with ID: $reportId");
    } else {
      print("Insert returned empty list.");
    }
  } catch (e) {
    print("Insert failed: $e");
  }

  if (reportId != null) {
    print("\n3. Attempting to update the status of the report to Accepted...");
    try {
      final updateRes = await client.from('incident_reports').update({
        'status': 'Accepted',
        'admin_remark': 'Admin approved this report',
      }).eq('id', reportId).select();

      print("Update result: $updateRes");
    } catch (e) {
      print("Update failed with exception: $e");
    }

    print("\n4. Cleaning up test report...");
    try {
      await client.from('incident_reports').delete().eq('id', reportId);
      print("Cleaned up successfully");
    } catch (e) {
      print("Cleanup failed: $e");
    }
  }

  print("\n5. Cleaning up test user...");
  try {
    await client.auth.signOut();
    print("Signed out successfully");
  } catch (e) {
    print("Sign out failed: $e");
  }
}
