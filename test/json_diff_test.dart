// Copyright 2014 Google Inc. All Rights Reserved.
// Licensed under the Apache License, Version 2.0, found in the LICENSE file.

/// Unit tests for json_diff.
library json_diff_tests;

import 'dart:convert';

import 'package:json_diff/json_diff.dart';
import 'package:test/test.dart';

void main() {
  JsonDiffer differ;

  test('JsonDiffer throws FormatException', () {
    expect(() => JsonDiffer('{', '{}'), throwsFormatException);
    expect(() => JsonDiffer('', ''), throwsFormatException);
  });

  test('JsonDiffer diff() identical objects', () {
    differ = JsonDiffer('{"a": 1}', '{"a": 1}');
    final node = differ.diff();
    expect(node.added, isEmpty);
    expect(node.removed, isEmpty);
    expect(node.changed, isEmpty);
    expect(node.node, isEmpty);
  });

  test('JsonDiffer diff() identical lists', () {
    differ = JsonDiffer.fromJson([1, 2, 3], [1, 2, 3]);
    final node = differ.diff();
    expect(node.added, isEmpty);
    expect(node.removed, isEmpty);
    expect(node.changed, isEmpty);
    expect(node.node, isEmpty);
  });

  test('JsonDiffer diff() comparing a list and a map', () {
    final differ = JsonDiffer.fromJson([1, 2], {'foo': 'bar'});
    final node = differ.diff();
    expect(node.added, isEmpty);
    expect(node.removed, isEmpty);
    expect(node.changed[''], [
      [1, 2],
      {'foo': 'bar'}
    ]);
    expect(node.node, isEmpty);
  });

  test('JsonDiffer diff() with a new value', () {
    differ = JsonDiffer('{"a": 1}', '{"a": 1, "b": 2}');
    final node = differ.diff();
    expect(node.added, hasLength(1));
    expect(node.added['b'], equals(2));
    expect(node.removed, isEmpty);
    expect(node.changed, isEmpty);
    expect(node.node, isEmpty);
  });

  test('JsonDiffer diff() lists with a new value', () {
    differ = JsonDiffer.fromJson([1, 2, 3], [1, 2, 3, 4]);
    final node = differ.diff();
    expect(node.added[3], equals(4));
    expect(node.removed, isEmpty);
    expect(node.changed, isEmpty);
    expect(node.node, isEmpty);
  });

  test('JsonDiffer diff() with a deep new value', () {
    differ = JsonDiffer('{"a": {"x": 1}}', '{"a": {"x": 1, "y": {"p": 2}}}');
    final node = differ.diff();
    expect(node.added, isEmpty);
    expect(node.removed, isEmpty);
    expect(node.changed, isEmpty);
    expect(node.node, hasLength(1));
    expect(node.node['a'].added, hasLength(1));
    expect(node.node['a'].added['y'], equals({'p': 2}));
    expect(node.node['a'].removed, isEmpty);
    expect(node.node['a'].changed, isEmpty);
  });

  test('JsonDiffer diff() with a removed value', () {
    differ = JsonDiffer('{"a": 1, "b": 2}', '{"a": 1}');
    final node = differ.diff();
    expect(node.added, isEmpty);
    expect(node.removed, hasLength(1));
    expect(node.removed['b'], equals(2));
    expect(node.changed, isEmpty);
    expect(node.node, isEmpty);
  });

  test('JsonDiffer diff() lists with a removed value', () {
    differ = JsonDiffer.fromJson([1, 2, 3, 4], [1, 2, 3]);
    final node = differ.diff();
    expect(node.added, isEmpty);
    expect(node.removed[3], equals(4));
    expect(node.changed, isEmpty);
    expect(node.node, isEmpty);
  });

  test('JsonDiffer diff() with a changed value', () {
    differ = JsonDiffer('{"a": 1}', '{"a": 2}');
    final node = differ.diff();
    expect(node.added, isEmpty);
    expect(node.removed, isEmpty);
    expect(node.changed, hasLength(1));
    expect(node.changed['a'], equals([1, 2]));
    expect(node.node, isEmpty);
  });

  test('JsonDiffer diff() lists with a changed value', () {
    differ = JsonDiffer.fromJson([1, 2, 3, 4], [1, 2, 9, 4]);
    final node = differ.diff();
    expect(node.added, isEmpty);
    expect(node.removed, isEmpty);
    expect(node.changed[2], equals([3, 9]));
    expect(node.node, isEmpty);
  });

  test('JsonDiffer diff() with a deeply changed value', () {
    differ = JsonDiffer('{"a": {"x": 1}}', '{"a": {"x": 2}}');
    final node = differ.diff();
    expect(node.added, isEmpty);
    expect(node.removed, isEmpty);
    expect(node.changed, isEmpty);
    expect(node.node, hasLength(1));
    final innerNode = node.node['a'];
    expect(innerNode.changed, hasLength(1));
    expect(innerNode.changed['x'], equals([1, 2]));
  });

  test('JsonDiffer diff() with a new value at the end of a list', () {
    differ = JsonDiffer('{"a": [1,2]}', '{"a": [1,2,4]}');
    final node = differ.diff();
    expect(node.added, isEmpty);
    expect(node.removed, isEmpty);
    expect(node.changed, isEmpty);
    expect(node.node, hasLength(1));
    expect(node.node['a'].added, hasLength(1));
    expect(node.node['a'].added[2], equals(4));
    expect(node.node['a'].removed, isEmpty);
    expect(node.node['a'].changed, isEmpty);
  });

  test('JsonDiffer diff() with a new value in the middle of a list', () {
    differ = JsonDiffer('{"a": [1,2]}', '{"a": [1,4,2]}');
    final node = differ.diff();
    expect(node.added, isEmpty);
    expect(node.removed, isEmpty);
    expect(node.changed, isEmpty);
    expect(node.node, hasLength(1));
    expect(node.node['a'].added, hasLength(1));
    expect(node.node['a'].added[1], equals(4));
    expect(node.node['a'].removed, isEmpty);
    expect(node.node['a'].changed, isEmpty);
  });

  test('JsonDiffer diff() with multiple new values in the middle of a list',
      () {
    differ = JsonDiffer('{"a": [1,2]}', '{"a": [1,4,8,2]}');
    final node = differ.diff();
    expect(node.added, isEmpty);
    expect(node.removed, isEmpty);
    expect(node.changed, isEmpty);
    expect(node.node, hasLength(1));
    expect(node.node['a'].added, hasLength(2));
    expect(node.node['a'].added[1], equals(4));
    expect(node.node['a'].added[2], equals(8));
    expect(node.node['a'].removed, isEmpty);
    expect(node.node['a'].changed, isEmpty);
  });

  test('JsonDiffer diff() with a new value at the start of a list', () {
    differ = JsonDiffer('{"a": [1,2]}', '{"a": [4,1,2]}');
    final node = differ.diff();
    expect(node.added, isEmpty);
    expect(node.removed, isEmpty);
    expect(node.changed, isEmpty);
    expect(node.node, hasLength(1));
    expect(node.node['a'].added, hasLength(1));
    expect(node.node['a'].added[0], equals(4));
    expect(node.node['a'].removed, isEmpty);
    expect(node.node['a'].changed, isEmpty);
  });

  test('JsonDiffer diff() with a new object at the start of a list', () {
    differ = JsonDiffer(
        '{"a": [{"x":1},{"y":2}]}', '{"a": [{"z":4},{"x":1},{"y":2}]}');
    final node = differ.diff();
    expect(node.added, isEmpty);
    expect(node.removed, isEmpty);
    expect(node.changed, isEmpty);
    expect(node.node, hasLength(1));
    expect(node.node['a'].added, hasLength(1));
    expect(node.node['a'].added[0], equals({'z': 4}));
    expect(node.node['a'].removed, isEmpty);
    expect(node.node['a'].changed, isEmpty);
  });

  test('JsonDiffer diff() with multiple new values at the start of a list', () {
    differ = JsonDiffer('{"a": [1,2]}', '{"a": [4,8,1,2]}');
    final node = differ.diff();
    expect(node.added, isEmpty);
    expect(node.removed, isEmpty);
    expect(node.changed, isEmpty);
    expect(node.node, hasLength(1));
    expect(node.node['a'].added, hasLength(2));
    expect(node.node['a'].added[0], equals(4));
    expect(node.node['a'].added[1], equals(8));
    expect(node.node['a'].removed, isEmpty);
    expect(node.node['a'].changed, isEmpty);
  });

  test('JsonDiffer diff() with a changed value at the start of a list', () {
    differ = JsonDiffer.fromJson({
      'a': [
        {'b': 1}
      ]
    }, {
      'a': [
        {'b': 2}
      ]
    });
    final node = differ.diff();
    expect(node.added, isEmpty);
    expect(node.removed, isEmpty);
    expect(node.changed, isEmpty);
    expect(node.node, hasLength(1));
    expect(node.node['a'].added, isEmpty);
    expect(node.node['a'].removed, isEmpty);
    expect(node.node['a'].changed, isEmpty);
    expect(node.node['a'].node[0].changed, hasLength(1));
    expect(node.node['a'].node[0].changed['b'], equals([1, 2]));
  });

  test(
      'JsonDiffer diff() with multiple changed values at different indexes of a list',
      () {
    final node = JsonDiffer.fromJson({
      'primary': [
        {
          'resolvers': [
            'foo',
          ],
        },
        {
          'resolvers': [
            'same on both',
          ],
        },
      ],
    }, {
      'primary': [
        {
          'resolvers': [
            'bar',
          ],
        },
        {
          'resolvers': [
            'same on both',
            'added',
          ],
        },
      ],
    }).diff();

    expect(node.node['primary'].node[0].node['resolvers'].changed[0],
        equals(['foo', 'bar']));
    expect(node.node['primary'].node[1].node['resolvers'].added[1],
        equals('added'));
  });

  test('JsonDiffer diff() with added element after changed element', () {
    const left = {
      'field': [1]
    };

    const right = {
      'field': [2, 'added']
    };

    final node = JsonDiffer.fromJson(left, right).diff();

    expect(node.node['field'].changed[0], equals([1, 2]));
    expect(node.node['field'].added[1], equals('added'));
  });

  test('JsonDiffer diff() with complex elements moved in list', () {
    final node = JsonDiffer.fromJson({
      'list': [
        'xxx',
        'xxx',
        {'foo': 1},
        [2],
      ],
    }, {
      'list': [
        [2],
        {'foo': 1},
        'xxx',
        'xxx',
      ],
    }).diff();

    expect(node.node['list'].moved[2], equals(1));
    expect(node.node['list'].moved[3], equals(0));
  });
}

String jsonFrom(Map<String, Object> obj) => JsonEncoder().convert(obj);
