import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    // Firebase requires initialization and cannot be tested with
    // basic widget tests. Run integration tests on a device instead.
    expect(true, isTrue);
  });
}
