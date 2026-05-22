import 'package:supabase/supabase.dart';

void main() async {
  final client = SupabaseClient(
    'https://jwsibafhwkujlpgzqaph.supabase.co',
    'sb_publishable_Ann0sNjsSu8QeM9KVGo72Q_g1gz9pvv',
    authOptions: const AuthClientOptions(authFlowType: AuthFlowType.implicit),
  );

  print("Testing insert with status: Pending");
  try {
    final res = await client.from('incident_reports').insert({
      'title': 'Test Status Pending',
      'description': 'Testing pending status check constraint',
      'location': 'Test Location',
      'status': 'Pending',
    }).select();
    print("Insert Pending succeeded: $res");
    if (res.isNotEmpty) {
      final insertedId = res.first['id'];
      await client.from('incident_reports').delete().eq('id', insertedId);
      print("Cleaned up Pending insert");
    }
  } catch (e) {
    print("Insert Pending failed: $e");
  }

  print("\nTesting insert with status: Accepted");
  try {
    final res = await client.from('incident_reports').insert({
      'title': 'Test Status Accepted',
      'description': 'Testing accepted status check constraint',
      'location': 'Test Location',
      'status': 'Accepted',
    }).select();
    print("Insert Accepted succeeded: $res");
    if (res.isNotEmpty) {
      final insertedId = res.first['id'];
      await client.from('incident_reports').delete().eq('id', insertedId);
      print("Cleaned up Accepted insert");
    }
  } catch (e) {
    print("Insert Accepted failed: $e");
  }

  print("\nTesting insert with status: Approved");
  try {
    final res = await client.from('incident_reports').insert({
      'title': 'Test Status Approved',
      'description': 'Testing approved status check constraint',
      'location': 'Test Location',
      'status': 'Approved',
    }).select();
    print("Insert Approved succeeded: $res");
    if (res.isNotEmpty) {
      final insertedId = res.first['id'];
      await client.from('incident_reports').delete().eq('id', insertedId);
      print("Cleaned up Approved insert");
    }
  } catch (e) {
    print("Insert Approved failed: $e");
  }

  print("\nTesting update on an existing report anonymously...");
  try {
    // 1. Insert a report first
    final insertRes = await client.from('incident_reports').insert({
      'title': 'Test Update Status',
      'description': 'Testing update anonymously',
      'location': 'Test Location',
      'status': 'Pending',
    }).select();

    if (insertRes.isNotEmpty) {
      final id = insertRes.first['id'];
      print("Inserted test report with ID: $id. Now attempting updates...");

      // 2. Try to update title
      final updateTitleRes = await client.from('incident_reports').update({
        'title': 'New Test Title',
      }).eq('id', id).select();
      print("Update title result: $updateTitleRes");

      // 3. Try to update status
      final updateStatusRes = await client.from('incident_reports').update({
        'status': 'Accepted',
      }).eq('id', id).select();
      print("Update status result: $updateStatusRes");

      // 4. Try to update admin_remark
      final updateRemarkRes = await client.from('incident_reports').update({
        'admin_remark': 'Tested remark',
      }).eq('id', id).select();
      print("Update admin_remark result: $updateRemarkRes");

      // Clean up
      await client.from('incident_reports').delete().eq('id', id);
      print("Cleaned up after update test");
    } else {
      print("Failed to insert for update test");
    }
  } catch (e) {
    print("Update failed with exception: $e");
  }
}




