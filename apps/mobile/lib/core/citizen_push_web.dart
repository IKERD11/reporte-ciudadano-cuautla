import 'dart:js_interop';

@JS('setCitizenPush')
external JSPromise<JSBoolean> _setPush(
  JSString endpoint,
  JSString token,
  JSBoolean enabled,
  JSString key,
);

Future<bool> setCitizenPush(
  String endpoint,
  String token,
  bool enabled,
) async => (await _setPush(
  endpoint.toJS,
  token.toJS,
  enabled.toJS,
  const String.fromEnvironment('VAPID_PUBLIC_KEY').toJS,
).toDart).toDart;
