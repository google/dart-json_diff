// Copyright 2015 Google Inc. All Rights Reserved.
// Licensed under the Apache License, Version 2.0, found in the LICENSE file.

/// Unit tests for json_diff's ignored feature.
library ignored_tests;

import 'package:json_diff/json_diff.dart';
import 'package:test/test.dart';

void main() {
  JsonDiffer differ;

  test('JsonDiffer ignores ignored and changed object keys', () {
    differ = JsonDiffer('{"a": {"x": 1}}', '{"a": {"x": 2}}');
    differ.ignored.add('x');
    final node = differ.diff();
    expect(node.added, isEmpty);
    expect(node.removed, isEmpty);
    expect(node.changed, isEmpty);
    expect(node.node, isEmpty);
  });

  test('JsonDiffer ignores ignored and new object keys', () {
    differ = JsonDiffer('{"a": {}}', '{"a": {"x": 2}}');
    differ.ignored.add('x');
    final node = differ.diff();
    expect(node.added, isEmpty);
    expect(node.removed, isEmpty);
    expect(node.changed, isEmpty);
    expect(node.node, isEmpty);
  });

  test('JsonDiffer ignores ignored and removed object keys', () {
    differ = JsonDiffer('{"a": {"x": 1}}', '{"a": {}}');
    differ.ignored.add('x');
    final node = differ.diff();
    expect(node.added, isEmpty);
    expect(node.removed, isEmpty);
    expect(node.changed, isEmpty);
    expect(node.node, isEmpty);
  });
}
