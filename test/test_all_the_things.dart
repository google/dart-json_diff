import 'package:test/test.dart';

import 'atomics_test.dart' as atomics_test;
import 'ignored_test.dart' as ignored_test;
import 'json_diff_test.dart' as json_diff_test;

void main() {
  group('atomics', atomics_test.main);
  group('ignored', ignored_test.main);
  group('json_diff', json_diff_test.main);
}
