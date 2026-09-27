import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';
import 'package:supabase_flutter/supabase_flutter.dart';

abstract class ReportRepository {
  Future<Map<String, dynamic>> call(
    String action, [
    Map<String, dynamic> values = const {},
  ]);
}

class SupabaseReportRepository implements ReportRepository {
  SupabaseReportRepository(this.client);
  final SupabaseClient client;
  @override
  Future<Map<String, dynamic>> call(
    String action, [
    Map<String, dynamic> values = const {},
  ]) async {
    if (action.startsWith('notifications_')) {
      final data = await client.rpc(
        'citizen_notifications',
        params: {
          'p_action': action.substring('notifications_'.length),
          'p_id': values['id'],
          'p_offset': values['offset'] ?? 0,
        },
      );
      return Map<String, dynamic>.from(data as Map);
    }
    try {
      final result = await client.functions.invoke(
        'report-pilot',
        body: {'action': action, ...values},
      );
      return Map<String, dynamic>.from(result.data as Map);
    } on FunctionException catch (e) {
      throw Exception(
        e.details is Map
            ? e.details['error']
            : 'No se pudo completar la operación.',
      );
    }
  }
}

String reportRequestKey() {
  final random = Random.secure();
  final b = List.generate(16, (_) => random.nextInt(256));
  b[6] = (b[6] & 15) | 64;
  b[8] = (b[8] & 63) | 128;
  final h = b.map((v) => v.toRadixString(16).padLeft(2, '0')).join();
  return '${h.substring(0, 8)}-${h.substring(8, 12)}-${h.substring(12, 16)}-${h.substring(16, 20)}-${h.substring(20)}';
}

Map<String, dynamic> reportSubmission(
  String key,
  Map<String, dynamic> payload,
  List<Uint8List> photos,
) => {
  'request_key': key,
  'payload': payload,
  'photos': photos.map(base64Encode).toList(),
};
