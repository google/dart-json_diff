// Copyright 2014 Google Inc. All Rights Reserved.
// Licensed under the Apache License, Version 2.0, found in the LICENSE file.

part of json_diff;

/// A configurable class that can produce a diff of two JSON Strings.
class JsonDiffer {
  Map<String, Object> leftJson, rightJson;
  final List<String> atomics = <String>[];
  final List<String> metadataToKeep = <String>[];
  final List<String> ignored = <String>[];

  /// Constructs a new JsonDiffer using [leftString] and [rightString], two
  /// JSON objects represented as Dart strings.
  ///
  /// If the two JSON objects that need to be diffed are only available as
  /// Dart Maps, you can use the
  /// [dart:convert](https://api.dartlang.org/apidocs/channels/stable/dartdoc-viewer/dart:convert)
  /// library to encode each Map into a JSON String.
  JsonDiffer(
    String leftString,
    String rightString,
  ) {
    Object _leftJson = jsonDecode(leftString);
    Object _rightJson = jsonDecode(rightString);

    if (_leftJson is Map<String, Object> && _rightJson is Map<String, Object>) {
      leftJson = _leftJson;
      rightJson = _rightJson;
    } else {
      throw FormatException('JSON must be a single object');
    }
  }

  JsonDiffer.fromJson(
    Map<String, Object> leftJson,
    Map<String, Object> rightJson,
  ) {
    if (leftJson != null && rightJson != null) {
      this.leftJson = leftJson;
      this.rightJson = rightJson;
    } else {
      throw FormatException('JSON must not be null');
    }
  }

  /// Throws an exception if the values of each of the [topLevelFields] are not
  /// equal.
  ///
  /// This is useful as a sanity check before diffing two JSON objects that are
  /// expected to be partially identical. For example, if you are comparing
  /// two historical versions of the same object, then each one should have the
  /// same "name" field:
  ///
  ///     // Instantiate differ.
  ///     differ.ensureIdentical(['name']);
  ///     // Perform diff.
  void ensureIdentical(List<String> topLevelFields) {
    for (final field in topLevelFields) {
      if (!leftJson.containsKey(field)) {
        throw UncomparableJsonException('left does not contain field "$field"');
      }
      if (!rightJson.containsKey(field)) {
        throw UncomparableJsonException(
            'right does not contain field "$field"');
      }
      if (leftJson[field] != rightJson[field]) {
        throw UncomparableJsonException(
            'Unequal values for field "$field": ${leftJson[field]} vs ${rightJson[field]}');
      }
    }
  }

  /// Compare the two JSON Strings, producing a [DiffNode].
  ///
  /// The differ will walk the entire object graph of each JSON object,
  /// tracking all additions, deletions, and changes. Please see the
  /// documentation for [DiffNode] to understand how to access the differences
  /// found between the two JSON Strings.
  DiffNode diff() => _diffObjects(leftJson, rightJson, '')..prune();

  DiffNode _diffObjects(
      Map<String, Object> left, Map<String, Object> right, String path) {
    final node = DiffNode();
    _keepMetadata(node, left, right);
    left.forEach((String key, Object leftValue) {
      if (ignored.contains(key)) {
        return;
      }

      if (!right.containsKey(key)) {
        // key is missing from right.
        node.removed[key] = leftValue;
        return;
      }

      final rightValue = right[key];
      if (atomics.contains(key) &&
          leftValue.toString() != rightValue.toString()) {
        // Treat leftValue and rightValue as atomic objects, even if they are
        // deep maps or some such thing.
        node.changed[key] = [leftValue, rightValue];
      } else if (leftValue is List && rightValue is List) {
        node[key] = _diffLists(leftValue, rightValue, key, '$path.$key');
      } else if (leftValue is Map<String, Object> &&
          rightValue is Map<String, Object>) {
        node[key] = _diffObjects(leftValue, rightValue, '$path.$key');
      } else if (leftValue != rightValue) {
        // value is different between [left] and [right]
        node.changed[key] = [leftValue, rightValue];
      }
    });

    right.forEach((String key, Object value) {
      if (ignored.contains(key)) {
        return;
      }

      if (!left.containsKey(key)) {
        // key is missing from left.
        node.added[key] = value;
      }
    });

    return node;
  }

  bool _deepEquals(e1, e2) => DeepCollectionEquality.unordered().equals(e1, e2);

  DiffNode _diffLists(
      List<Object> left, List<Object> right, String parentKey, String path) {
    final node = DiffNode();
    var leftHand = 0;
    var leftFoot = 0;
    var rightHand = 0;
    var rightFoot = 0;
    while (leftFoot < left.length && rightFoot < right.length) {
      if (!_deepEquals(left[leftFoot], right[rightFoot])) {
        var foundMissing = false;
        // Walk hands up one at a time. Feet keep track of where we were.
        while (true) {
          rightHand++;
          if (rightHand < right.length &&
              _deepEquals(left[leftFoot], right[rightHand])) {
            // Found it: the right elements at [rightFoot, rightHand-1] were added in right.
            for (var i = rightFoot; i < rightHand; i++) {
              node.added[i.toString()] = right[i];
            }
            rightFoot = rightHand;
            leftHand = leftFoot;
            foundMissing = true;
            break;
          }

          leftHand++;
          if (leftHand < left.length &&
              _deepEquals(left[leftHand], right[rightFoot])) {
            // Found it: The left elements at [leftFoot, leftHand-1] were removed from left.
            for (var i = leftFoot; i < leftHand; i++) {
              node.removed[i.toString()] = left[i];
            }
            leftFoot = leftHand;
            rightHand = rightFoot;
            foundMissing = true;
            break;
          }

          if (leftHand >= left.length && rightHand >= right.length) {
            break;
          }
        }

        if (!foundMissing) {
          // Never found left[leftFoot] in right, nor right[rightFoot] in left.
          // This must just be a changed value.
          // TODO: This notation is wrong for a case such as:
          //     [1,2,3,4,5,6] => [1,4,5,7]
          //     changed.first = [[5, 6], [3,7]
          final leftObject = left[leftFoot];
          final rightObject = right[rightFoot];
          if (parentKey != null &&
              atomics.contains(parentKey + '[]') &&
              leftObject.toString() != rightObject.toString()) {
            // Treat leftValue and rightValue as atomic objects, even if they are
            // deep maps or some such thing.
            node.changed[leftFoot.toString()] = [leftObject, rightObject];
          } else if (leftObject is Map<String, Object> &&
              rightObject is Map<String, Object>) {
            node[leftFoot.toString()] =
                _diffObjects(leftObject, rightObject, '$path.$leftFoot');
          } else if (leftObject is List && rightObject is List) {
            node[leftFoot.toString()] =
                _diffLists(leftObject, rightObject, null, '$path.$leftFoot');
          } else {
            node.changed[leftFoot.toString()] = [leftObject, rightObject];
          }
        }
      }
      leftHand++;
      rightHand++;
      leftFoot++;
      rightFoot++;
    }

    // Any new elements at the end of right.
    for (var i = rightFoot; i < right.length; i++) {
      node.added[i.toString()] = right[i];
    }

    // Any removed elements at the end of left.
    for (var i = leftFoot; i < left.length; i++) {
      node.removed[i.toString()] = left[i];
    }

    return node;
  }

  void _keepMetadata(DiffNode node, Map left, Map right) {
    metadataToKeep.forEach((String key) {
      if (left.containsKey(key) &&
          right.containsKey(key) &&
          left[key] == right[key]) {
        node.metadata[key] = left[key];
      }
    });
  }
}

/// An exception that is thrown when two JSON Strings did not pass a basic sanity test.
class UncomparableJsonException implements Exception {
  final String msg;

  const UncomparableJsonException(this.msg);

  @override
  String toString() => 'UncomparableJsonException: $msg';
}
