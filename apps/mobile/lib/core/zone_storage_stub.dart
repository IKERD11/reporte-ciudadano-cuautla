final _zones = <String, String>{};
String? readZone(String actor) => _zones[actor];
void writeZone(String actor, String value) => _zones[actor] = value;
