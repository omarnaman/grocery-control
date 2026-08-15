import 'package:flutter_test/flutter_test.dart';
import 'package:grocery_control/utils/join_payload.dart';

void main() {
  test('parses a raw group id', () {
    expect(parseJoinPayload('  abc123  '), {'Id': 'abc123'});
  });

  test('parses QR JSON payload', () {
    const json = '{"Id": "grp1", "Action": "Join group Family"}';
    expect(parseJoinPayload(json)?['Id'], 'grp1');
  });

  test('rejects empty and invalid JSON', () {
    expect(parseJoinPayload(''), isNull);
    expect(parseJoinPayload('   '), isNull);
    expect(parseJoinPayload('{not json'), isNull);
    expect(parseJoinPayload('{"Action": "Join"}'), isNull);
  });
}
