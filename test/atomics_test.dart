// Copyright 2015 Google Inc. All Rights Reserved.
// Licensed under the Apache License, Version 2.0, found in the LICENSE file.

/// Unit tests for json_diff's atomics feature.
library atomics_tests;

import 'package:json_diff/json_diff.dart';
import 'package:test/test.dart';

void main() {
  JsonDiffer differ;

  test('JsonDiffer keeps changed top-level atomics whole', () {
    differ = JsonDiffer('{"a": {"x": 1}}', '{"a": {"x": 2}}');
    differ.atomics.add('a');
    final node = differ.diff();
    expect(node.added, isEmpty);
    expect(node.removed, isEmpty);
    expect(node.changed, hasLength(1));
    expect(
        node.changed['a'],
        equals([
          {'x': 1},
          {'x': 2}
        ]));
  });

  test('JsonDiffer keeps new top-level atomics whole', () {
    differ = JsonDiffer('{}', '{"a": {"x": 2}}');
    differ.atomics.add('a');
    final node = differ.diff();
    expect(node.removed, isEmpty);
    expect(node.changed, isEmpty);
    expect(node.added, hasLength(1));
    expect(
        node.added,
        equals({
          'a': {'x': 2}
        }));
  });

  test('JsonDiffer keeps removed top-level atomics whole', () {
    differ = JsonDiffer('{"a": {"x": 1}}', '{}');
    differ.atomics.add('a');
    final node = differ.diff();
    expect(node.changed, isEmpty);
    expect(node.added, isEmpty);
    expect(node.removed, hasLength(1));
    expect(
        node.removed,
        equals({
          'a': {'x': 1}
        }));
  });

  test('JsonDiffer doesn\'t treat unchanged atomics differently', () {
    differ = JsonDiffer('{"a": {"x": 1}}', '{"a": {"x": 1}}');
    differ.atomics.add('a');
    final node = differ.diff();
    expect(node.added, isEmpty);
    expect(node.removed, isEmpty);
    expect(node.changed, isEmpty);
  });

  test('JsonDiffer keeps various atomics whole', () {
    differ = JsonDiffer('{"a": {"x": {"y": {"z": 1}}, "y": {"z": 3}}}',
        '{"a": {"x": {"y": {"z": 2}}, "y": {"z": 4}}}');
    differ.atomics.add('y');
    final node = differ.diff();
    expect(node.added, isEmpty);
    expect(node.removed, isEmpty);
    expect(node.changed, isEmpty);
    expect(node.node, hasLength(1));

    var innerNode = node.node['a']!;
    expect(innerNode.changed, hasLength(1));
    expect(
        innerNode.changed['y'],
        equals([
          {'z': 3},
          {'z': 4}
        ]));

    innerNode = node.node['a']!['x']!;
    expect(innerNode.changed, hasLength(1));
    expect(
        innerNode.changed['y'],
        equals([
          {'z': 1},
          {'z': 2}
        ]));
  });
}
