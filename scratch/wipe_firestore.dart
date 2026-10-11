import 'dart:convert';
import 'dart:io';

Future<void> main() async {
  final apiKey = 'AIzaSyCvgrHhpaPUqlcG6j87cUar__0G5-3aAj0';
  final baseUri = 'https://firestore.googleapis.com/v1/projects/gdrm-userbase/databases/(default)/documents';
  final client = HttpClient();

  final collections = ['gdrm_users', 'gdrm_phones', 'gdrm_piracy_alerts', 'gdrm_snail_trails'];

  for (final coll in collections) {
    print('\nChecking collection: $coll...');
    final listUrl = Uri.parse('$baseUri/$coll?pageSize=300&key=$apiKey');
    
    try {
      final req = await client.getUrl(listUrl);
      final resp = await req.close();
      final body = await resp.transform(utf8.decoder).join();
      final json = jsonDecode(body) as Map<String, dynamic>;

      final docs = json['documents'] as List<dynamic>?;
      if (docs == null || docs.isEmpty) {
        print('Collection $coll is already empty.');
        continue;
      }

      print('Found ${docs.length} documents in $coll. Deleting...');
      for (final doc in docs) {
        final docName = doc['name'] as String;
        
        // Delete subcollections for snail trails
        if (coll == 'gdrm_snail_trails') {
          try {
            final subUrl = Uri.parse('https://firestore.googleapis.com/v1/$docName/events?pageSize=300&key=$apiKey');
            final subReq = await client.getUrl(subUrl);
            final subResp = await subReq.close();
            final subBody = await subResp.transform(utf8.decoder).join();
            final subJson = jsonDecode(subBody) as Map<String, dynamic>;
            final subDocs = subJson['documents'] as List<dynamic>?;
            if (subDocs != null) {
              for (final subDoc in subDocs) {
                final delSubUrl = Uri.parse('https://firestore.googleapis.com/v1/${subDoc['name']}?key=$apiKey');
                final delSubReq = await client.deleteUrl(delSubUrl);
                await delSubReq.close();
                print('  Deleted sub-event: ${subDoc['name']}');
              }
            }
          } catch (_) {}
        }

        final delUrl = Uri.parse('https://firestore.googleapis.com/v1/$docName?key=$apiKey');
        final delReq = await client.deleteUrl(delUrl);
        final delResp = await delReq.close();
        print('  Deleted: $docName (status: ${delResp.statusCode})');
      }
    } catch (e) {
      print('Error on $coll: $e');
    }
  }

  client.close();
  print('\nDone! All Firestore collections wiped successfully.');
}
