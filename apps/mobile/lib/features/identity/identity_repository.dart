import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

abstract interface class IdentityRepository {
  Future<Map<String, dynamic>> context();
  Future<Map<String, dynamic>> begin(String requestKey);
  Future<Map<String, dynamic>> upload(String caseId, String side);
  Future<Map<String, dynamic>> submit(String caseId);
}

class SupabaseIdentityRepository implements IdentityRepository {
  SupabaseIdentityRepository(this.client);
  final SupabaseClient client;
  Future<Map<String, dynamic>> call(Map<String, dynamic> body) async {
    final response = await client.functions.invoke(
      'identity-pilot',
      body: body,
    );
    final result = Map<String, dynamic>.from(response.data as Map);
    if (result['mode'] != 'synthetic' ||
        result['real_capture_enabled'] != false) {
      throw StateError('El servidor no está en modo de pruebas sintéticas.');
    }
    return result;
  }

  @override
  Future<Map<String, dynamic>> context() => call({'action': 'context'});
  @override
  Future<Map<String, dynamic>> begin(String requestKey) => call({
    'action': 'begin',
    'request_key': requestKey,
    'consent': true,
    'notice_version': 'synthetic-v1',
  });
  @override
  Future<Map<String, dynamic>> upload(String caseId, String side) async {
    if (!['front', 'back'].contains(side)) throw ArgumentError('Lado inválido');
    final data = await rootBundle.load('assets/identity/$side.png');
    return call({
      'action': 'upload',
      'case_id': caseId,
      'side': side,
      'image': base64Encode(
        data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes),
      ),
    });
  }

  @override
  Future<Map<String, dynamic>> submit(String caseId) =>
      call({'action': 'submit', 'case_id': caseId});
}
