// Copyright 2014 Google Inc. All Rights Reserved.
// Licensed under the Apache License, Version 2.0, found in the LICENSE file.

/// Unit tests for json_diff.
library json_diff_tests;

import 'dart:convert';

import 'package:json_diff/json_diff.dart';
import 'package:test/test.dart';

void main() {
  JsonDiffer differ, necksDiffer;

  setUp(() {
    necksDiffer = JsonDiffer.fromJson(necks2000Map, necks2010Map);
  });

  test('JsonDiffer initializes OK', () {
    differ = JsonDiffer.fromJson({'a': 1}, {'b': 1});
    expect(differ.leftJson['a'], equals(1));

    expect(() => JsonDiffer('{}', '{}'), returnsNormally);

    expect(necksDiffer.leftJson['owner'], equals(necks2000Map['owner']));
    expect(necksDiffer.rightJson['owner'], equals(necks2010Map['owner']));
  });

  test('JsonDiffer throws FormatException', () {
    expect(() => JsonDiffer('{', '{}'), throwsFormatException);
    expect(() => JsonDiffer('', ''), throwsFormatException);
    // TODO: support List root nodes
    expect(() => JsonDiffer('[]', '[]'), throwsFormatException);
  });

  test('JsonDiffer ensureIdentical returns OK', () {
    expect(() => necksDiffer.ensureIdentical(['name']), returnsNormally);
  });

  test('JsonDiffer ensureIdentical raises', () {
    expect(() => necksDiffer.ensureIdentical(['owner']),
        throwsA(isA<UncomparableJsonException>()));
  });

  test('JsonDiffer diff() identical objects', () {
    differ = JsonDiffer('{"a": 1}', '{"a": 1}');
    final node = differ.diff();
    expect(node.added, isEmpty);
    expect(node.removed, isEmpty);
    expect(node.changed, isEmpty);
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

  test('JsonDiffer diff() with a changed value', () {
    differ = JsonDiffer('{"a": 1}', '{"a": 2}');
    final node = differ.diff();
    expect(node.added, isEmpty);
    expect(node.removed, isEmpty);
    expect(node.changed, hasLength(1));
    expect(node.changed['a'], equals([1, 2]));
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

const Map<String, Object> necks2000Map = {
  'name': 'New York Necks',
  'home_town': 'New York',
  'division': 'Atlantic',
  'founded': 1990,
  'owner': 'Tracy',
  'head_coach': 'Larry Lankworth',
  'players': {
    'Towering Tom': {
      'name': 'Towering Tom',
      'position': 'Forward',
      'Jersey': 13
    },
    'Benny Beanstalk': {
      'name': 'Benny Beanstalk',
      'position': 'Center',
      'Jersey': 21
    },
    'Elevated Elias': {
      'name': 'Elevated Elias',
      'position': 'Guard',
      'Jersey': 34
    },
    'Altitudinous Al': {
      'name': 'Altitudinous Al',
      'position': 'Forward',
      'Jersey': 55
    },
    'Lonny the Lofty': {
      'name': 'Lonny the Lofty',
      'position': 'Guard',
      'Jersey': 89
    }
  },
};

const Map<String, Object> necks2010Map = {
  'name': 'New York Necks',
  'home_town': 'New York',
  'division': 'Atlantic',
  'founded': 1990,
  'owner': 'Terry',
  'head_coach': 'Harold High-Reach',
  'players': {
    'Towering Tom': {
      'name': 'Towering Tom',
      'position': 'Forward',
      'Jersey': 13
    },
    'Tim Tallbert': {'name': 'Tim Tallbert', 'position': 'Center', 'Jersey': 8},
    'Elevated Elias': {
      'name': 'Elevated Elias',
      'position': 'Guard',
      'Jersey': 34
    },
    'Frank': {'name': 'Frank', 'position': 'Forward', 'Jersey': 5},
    'Lonny the Lofty': {
      'name': 'Lonny the Lofty',
      'position': 'Guard',
      'Jersey': 89
    }
  },
};
