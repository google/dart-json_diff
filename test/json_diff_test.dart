// Copyright 2014 Google Inc. All Rights Reserved.
// Licensed under the Apache License, Version 2.0, found in the LICENSE file.

/// Unit tests for json_diff.
library json_diff_tests;

import 'dart:convert';
import 'package:json_diff/json_diff.dart';
import 'package:test/test.dart';

void main() {
  String necks2000, necks2010;
  JsonDiffer differ, necksDiffer;

  setUp(() {
    necks2000 = jsonFrom(necks2000Map);
    necks2010 = jsonFrom(necks2010Map);
    necksDiffer = new JsonDiffer(necks2000, necks2010);
  });

  test('JsonDiffer initializes OK', () {
    differ = new JsonDiffer('{"a": 1}', '{"b": 1}');
    expect(differ.leftJson['a'], equals(1));

    expect(() => new JsonDiffer('{}', '{}'), returnsNormally);

    expect(necksDiffer.leftJson['owner'], equals(necks2000Map['owner']));
    expect(necksDiffer.rightJson['owner'], equals(necks2010Map['owner']));
  });

  test('JsonDiffer throws FormatException', () {
    expect(() => new JsonDiffer('{', '{}'), throwsFormatException);
    expect(() => new JsonDiffer('', ''), throwsFormatException);
    // TODO: support List root nodes
    expect(() => new JsonDiffer('[]', '[]'), throwsFormatException);
  });

  test('JsonDiffer ensureIdentical returns OK', () {
    expect(() => necksDiffer.ensureIdentical(['name']), returnsNormally);
  });

  test('JsonDiffer ensureIdentical raises', () {
    expect(() => necksDiffer.ensureIdentical(['owner']),
           throwsA(new isInstanceOf<UncomparableJsonException>()));
  });

  test('JsonDiffer diff() identical objects', () {
    differ = new JsonDiffer('{"a": 1}', '{"a": 1}');
    DiffNode node = differ.diff();
    expect(node.added, isEmpty);
    expect(node.removed, isEmpty);
    expect(node.changed, isEmpty);
    expect(node.node, isEmpty);
  });

  test('JsonDiffer diff() with a new value', () {
    differ = new JsonDiffer('{"a": 1}', '{"a": 1, "b": 2}');
    DiffNode node = differ.diff();
    expect(node.added, hasLength(1));
    expect(node.added['b'], equals(2));
    expect(node.removed, isEmpty);
    expect(node.changed, isEmpty);
    expect(node.node, isEmpty);
  });

  test('JsonDiffer diff() with a deep new value', () {
    differ = new JsonDiffer('{"a": {"x": 1}}', '{"a": {"x": 1, "y": {"p": 2}}}');
    DiffNode node = differ.diff();
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
    differ = new JsonDiffer('{"a": 1, "b": 2}', '{"a": 1}');
    DiffNode node = differ.diff();
    expect(node.added, isEmpty);
    expect(node.removed, hasLength(1));
    expect(node.removed['b'], equals(2));
    expect(node.changed, isEmpty);
    expect(node.node, isEmpty);
  });

  test('JsonDiffer diff() with a changed value', () {
    differ = new JsonDiffer('{"a": 1}', '{"a": 2}');
    DiffNode node = differ.diff();
    expect(node.added, isEmpty);
    expect(node.removed, isEmpty);
    expect(node.changed, hasLength(1));
    expect(node.changed['a'], equals([1, 2]));
    expect(node.node, isEmpty);
  });

  test('JsonDiffer diff() with a deeply changed value', () {
    differ = new JsonDiffer('{"a": {"x": 1}}', '{"a": {"x": 2}}');
    DiffNode node = differ.diff();
    expect(node.added, isEmpty);
    expect(node.removed, isEmpty);
    expect(node.changed, isEmpty);
    expect(node.node, hasLength(1));
    DiffNode innerNode = node.node['a'];
    expect(innerNode.changed, hasLength(1));
    expect(innerNode.changed['x'], equals([1, 2]));
  });

  test('JsonDiffer diff() with a new value at the end of a list', () {
    differ = new JsonDiffer('{"a": [1,2]}', '{"a": [1,2,4]}');
    DiffNode node = differ.diff();
    expect(node.added, isEmpty);
    expect(node.removed, isEmpty);
    expect(node.changed, isEmpty);
    expect(node.node, hasLength(1));
    expect(node.node['a'].added, hasLength(1));
    expect(node.node['a'].added['2'], equals(4));
    expect(node.node['a'].removed, isEmpty);
    expect(node.node['a'].changed, isEmpty);
  });

  test('JsonDiffer diff() with a new value in the middle of a list', () {
    differ = new JsonDiffer('{"a": [1,2]}', '{"a": [1,4,2]}');
    DiffNode node = differ.diff();
    expect(node.added, isEmpty);
    expect(node.removed, isEmpty);
    expect(node.changed, isEmpty);
    expect(node.node, hasLength(1));
    expect(node.node['a'].added, hasLength(1));
    expect(node.node['a'].added['1'], equals(4));
    expect(node.node['a'].removed, isEmpty);
    expect(node.node['a'].changed, isEmpty);
  });

  test('JsonDiffer diff() with multiple new values in the middle of a list', () {
    differ = new JsonDiffer('{"a": [1,2]}', '{"a": [1,4,8,2]}');
    DiffNode node = differ.diff();
    expect(node.added, isEmpty);
    expect(node.removed, isEmpty);
    expect(node.changed, isEmpty);
    expect(node.node, hasLength(1));
    expect(node.node['a'].added, hasLength(2));
    expect(node.node['a'].added['1'], equals(4));
    expect(node.node['a'].added['2'], equals(8));
    expect(node.node['a'].removed, isEmpty);
    expect(node.node['a'].changed, isEmpty);
  });

  test('JsonDiffer diff() with a new value at the start of a list', () {
    differ = new JsonDiffer('{"a": [1,2]}', '{"a": [4,1,2]}');
    DiffNode node = differ.diff();
    expect(node.added, isEmpty);
    expect(node.removed, isEmpty);
    expect(node.changed, isEmpty);
    expect(node.node, hasLength(1));
    expect(node.node['a'].added, hasLength(1));
    expect(node.node['a'].added['0'], equals(4));
    expect(node.node['a'].removed, isEmpty);
    expect(node.node['a'].changed, isEmpty);
  });

  test('JsonDiffer diff() with a new object at the start of a list', () {
    differ = new JsonDiffer('{"a": [{"x":1},{"y":2}]}', '{"a": [{"z":4},{"x":1},{"y":2}]}');
    DiffNode node = differ.diff();
    expect(node.added, isEmpty);
    expect(node.removed, isEmpty);
    expect(node.changed, isEmpty);
    expect(node.node, hasLength(1));
    expect(node.node['a'].added, hasLength(1));
    expect(node.node['a'].added['0'], equals({'z': 4}));
    expect(node.node['a'].removed, isEmpty);
    expect(node.node['a'].changed, isEmpty);
  });

  test('JsonDiffer diff() with multiple new values at the start of a list', () {
    differ = new JsonDiffer('{"a": [1,2]}', '{"a": [4,8,1,2]}');
    DiffNode node = differ.diff();
    expect(node.added, isEmpty);
    expect(node.removed, isEmpty);
    expect(node.changed, isEmpty);
    expect(node.node, hasLength(1));
    expect(node.node['a'].added, hasLength(2));
    expect(node.node['a'].added['0'], equals(4));
    expect(node.node['a'].added['1'], equals(8));
    expect(node.node['a'].removed, isEmpty);
    expect(node.node['a'].changed, isEmpty);
  });

  test('JsonDiffer diff() with a changed value at the start of a list', () {
    differ = new JsonDiffer('{"a": [{"b": 1}]}', '{"a": [{"b": 2}]}');
    DiffNode node = differ.diff();
    expect(node.added, isEmpty);
    expect(node.removed, isEmpty);
    expect(node.changed, isEmpty);
    expect(node.node, hasLength(1));
    expect(node.node['a'].added, isEmpty);
    expect(node.node['a'].removed, isEmpty);
    expect(node.node['a'].changed, isEmpty);
    expect(node.node['a'].node['0'].changed, hasLength(1));
    expect(node.node['a'].node['0'].changed['b'], equals([1, 2]));
  });

  // TODO: Test metadataToKeep
}

String jsonFrom(Map<String,Object> obj) =>
  new JsonEncoder().convert(obj);

const Map<String,Object> necks2000Map = const {
  'name': 'New York Necks',
  'home_town': 'New York',
  'division': 'Atlantic',
  'founded': 1990,
  'owner': 'Tracy',
  'head_coach': 'Larry Lankworth',
  'players': const {
    'Towering Tom':
      const { 'name': 'Towering Tom', 'position': 'Forward', 'Jersey': 13 },
    'Benny Beanstalk':
      const { 'name': 'Benny Beanstalk', 'position': 'Center', 'Jersey': 21 },
    'Elevated Elias':
      const { 'name': 'Elevated Elias', 'position': 'Guard', 'Jersey': 34 },
    'Altitudinous Al':
      const { 'name': 'Altitudinous Al', 'position': 'Forward', 'Jersey': 55 },
    'Lonny the Lofty':
      const { 'name': 'Lonny the Lofty', 'position': 'Guard', 'Jersey': 89 }
  },
};

const Map<String,Object> necks2010Map = const {
  'name': 'New York Necks',
  'home_town': 'New York',
  'division': 'Atlantic',
  'founded': 1990,
  'owner': 'Terry',
  'head_coach': 'Harold High-Reach',
  'players': const {
    'Towering Tom':
      const { 'name': 'Towering Tom', 'position': 'Forward', 'Jersey': 13 },
    'Tim Tallbert':
      const { 'name': 'Tim Tallbert', 'position': 'Center', 'Jersey': 8 },
    'Elevated Elias':
      const { 'name': 'Elevated Elias', 'position': 'Guard', 'Jersey': 34 },
    'Frank':
      const { 'name': 'Frank', 'position': 'Forward', 'Jersey': 5 },
    'Lonny the Lofty':
      const { 'name': 'Lonny the Lofty', 'position': 'Guard', 'Jersey': 89 }
  },
};
