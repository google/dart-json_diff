/// Unit tests for shapeshift.
library shapeshiftTests;

import 'dart:convert';
//import 'dart:io';

import 'package:shapeshift/shapeshift.dart';
//import 'package:mock/mock.dart';
import 'package:unittest/unittest.dart';

void main() {
  String necks2000, necks2010;
  JsonDiffer necksDiffer;
  
  setUp(() {
    necks2000 = jsonFrom(necks2000Map);
    necks2010 = jsonFrom(necks2010Map);
    necksDiffer = new JsonDiffer(necks2000, necks2010);
  });
  
  test('JsonDiffer initializes OK', () {
    JsonDiffer differ = new JsonDiffer(jsonFrom({'a': 1}), jsonFrom({'b': 1}));
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
    JsonDiffer differ = new JsonDiffer(jsonFrom({'a': 1}), jsonFrom({'a': 1}));
    DiffNode node = differ.diff();
    expect(node.added.isEmpty, isTrue);
    expect(node.removed.isEmpty, isTrue);
    expect(node.changed.isEmpty, isTrue);
  });
  
  test('JsonDiffer diff() with a changed value', () {
    JsonDiffer differ = new JsonDiffer(jsonFrom({'a': 1}), jsonFrom({'a': 2}));
    DiffNode node = differ.diff();
    expect(node.added, isEmpty);
    expect(node.removed, isEmpty);
    expect(node.changed.isNotEmpty, isTrue);
  });
}

String jsonFrom(Map<String,Object> obj) {
  return new JsonEncoder().convert(obj);
}

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
  }
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
  }
};