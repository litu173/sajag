import 'package:flutter_test/flutter_test.dart';
import 'package:sajag/core/updates.dart';

void main() {
  test('compares semantic versions', () {
    expect(isNewerVersion('1.1.0', '1.0.0'), isTrue);
    expect(isNewerVersion('v1.0.1', '1.0.0'), isTrue);
    expect(isNewerVersion('1.10.0', '1.9.9'), isTrue);
    expect(isNewerVersion('1.0.0', '1.0.0'), isFalse);
    expect(isNewerVersion('1.0.0', '1.0.0+5'), isFalse);
    expect(isNewerVersion('0.9.0', '1.0.0'), isFalse);
    expect(isNewerVersion('2', '1.9'), isTrue);
  });
}
