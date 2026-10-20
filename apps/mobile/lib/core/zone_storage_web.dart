import 'package:web/web.dart' as web;

String? readZone(String actor) {
  try {
    return web.window.localStorage.getItem('citizen.zone.$actor');
  } catch (_) {
    return null;
  }
}

void writeZone(String actor, String value) =>
    web.window.localStorage.setItem('citizen.zone.$actor', value);
