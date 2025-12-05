import 'package:tag_reader/shared_extensions.dart';
import 'package:test/test.dart';

void main() {
  test('01:10:00.00', () async {
    final millis = '01:10:00.00'.toMillis();
    final expectedMillis = Duration(hours: 1, minutes: 10).inMilliseconds;
    expect(millis, expectedMillis);
  });

  test('50:01.200', () async {
    final millis = '50:01.200'.toMillis();
    final expectedMillis = Duration(
      minutes: 50,
      seconds: 1,
      milliseconds: 200,
    ).inMilliseconds;
    expect(millis, expectedMillis);
  });

  test('21.10', () async {
    final millis = '21.10'.toMillis();
    final expectedMillis = Duration(
      seconds: 21,
      milliseconds: 10,
    ).inMilliseconds;
    expect(millis, expectedMillis);
  });

  test('abc:aaa.0', () async {
    final millis = 'abc:aaa.0'.toMillis();
    expect(millis == null, true);
  });

  test('empty', () async {
    final millis = ''.toMillis();
    expect(millis == null, true);
  });
}
