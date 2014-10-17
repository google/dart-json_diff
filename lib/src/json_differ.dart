part of json_diff;

class JsonDiffer {
  Map<String,Object> leftJson, rightJson;
  final List<String> atomics = new List<String>();
  final List<String> metadataToKeep = new List<String>();
  
  JsonDiffer(leftString, rightString) {
    Object _leftJson = new JsonDecoder().convert(leftString);
    Object _rightJson = new JsonDecoder().convert(rightString);
    
    if (_leftJson is Map && _rightJson is Map) {
      leftJson = _leftJson;
      rightJson = _rightJson;
    } else {
      throw new FormatException('JSON must be a single object');
    }
  }
  
  void ensureIdentical(List<String> topLevelFields) {
    for (String field in topLevelFields) {
      if (!leftJson.containsKey(field)) {
        throw new UncomparableJsonException('left does not contain field "$field"');
      }
      if (!rightJson.containsKey(field)) {
        throw new UncomparableJsonException('right does not contain field "$field"');
      }
      if (leftJson[field] != rightJson[field]) {
        throw new UncomparableJsonException(
            'Unequal values for field "$field": ${leftJson[field]} vs ${rightJson[field]}');
      }
    }
  }

  DiffNode diff() {
    Map<String,Object> added = new Map<String,Object>();
    Map<String,Object> removed = new Map<String,Object>();
    Map<String,Object> changed = new Map<String,Object>();

    DiffNode d = diffObjects(leftJson, rightJson);
    d.prune();
    return d;
  }

  DiffNode diffObjects(Map<String,Object> left, Map<String,Object> right) {
    DiffNode node = new DiffNode();
    keepMetadata(node, left, right);
    left.forEach((String key, Object leftValue) {
      if (!right.containsKey(key)) {
        // [key] is missing from [right]
        node.removed[key] = leftValue;
        return;
      }
      
      Object rightValue = right[key];
      if (atomics.contains(key) && leftValue.toString() != rightValue.toString()) {
        // Treat leftValue and rightValue as atomic objects, even if they are
        // deep maps or some such thing.
        node.changed[key] = [leftValue, rightValue];
      } else if (leftValue is List && rightValue is List) {
        node[key] = diffLists(leftValue, rightValue, key);
      } else if (leftValue is Map && rightValue is Map) {
        node[key] = diffObjects(leftValue, rightValue);
      } else if (leftValue != rightValue) {
        // value is different between [left] and [right]
        node.changed[key] = [leftValue, rightValue];
      }
    });
    
    right.forEach((String key, Object value) {
      if (!left.containsKey(key)) {
        // [key] is missing from [left]
        node.added[key] = value;
      }
    });
    
    return node;
  }

  bool deepEquals(e1, e2) => new DeepCollectionEquality().equals(e1, e2);

  DiffNode diffLists(List<Object> left, List<Object> right, String parentKey) {
    DiffNode node = new DiffNode();
    int leftHand = 0;
    int leftFoot = 0;
    int rightHand = 0;
    int rightFoot = 0;
    while (leftHand < left.length && rightHand < right.length) {
      if (!deepEquals(left[leftHand], right[rightHand])) {
        bool foundMissing = false;
        // Walk hands up one at a time. Feet keep track of where we were.
        while (true) {
          rightHand++;
          if (rightHand < right.length && deepEquals(left[leftFoot], right[rightHand])) {
            // Found it: the right elements at [rightFoot, rightHand-1] were added in right.
            for (int i=rightFoot; i<rightHand; i++) {
              node.added[i.toString()] = right[i];
            }
            rightFoot = rightHand;
            leftHand = leftFoot;
            foundMissing = true;
            break;
          }

          leftHand++;
          if (leftHand < left.length && deepEquals(left[leftHand], right[rightFoot])) {
            // Found it: The left elements at [leftFoot, leftHand-1] were removed from left.
            for (int i=leftFoot; i<leftHand; i++) {
              node.removed[i.toString()] = left[i];
            }
            leftFoot = leftHand;
            rightHand = rightFoot;
            foundMissing = true;
            break;
          }

          if (leftHand >= left.length && rightHand >= right.length) { break; }
        }

        if (!foundMissing) {
          // Never found left[leftFoot] in right, nor right[rightFoot] in left.
          // This must just be a changed value.
          // TODO: This notation is wrong for a case such as:
          //     [1,2,3,4,5,6] => [1,4,5,7]
          //     changed.first = [[5, 6], [3,7]
          if (atomics.contains(parentKey+"[]") && left[leftFoot].toString() != right[rightFoot].toString()) {
            // Treat leftValue and rightValue as atomic objects, even if they are
            // deep maps or some such thing.
            node.changed[leftFoot.toString()] = [left[leftFoot], right[rightFoot]];
          } else if (left[leftFoot] is Map && right[rightFoot] is Map) {
            node[leftFoot.toString()] = diffObjects(left[leftFoot], right[rightFoot]);
          } else if (left[leftFoot] is List && right[rightFoot] is List) {
            node[leftFoot.toString()] = diffLists(left[leftFoot], right[rightFoot], null);
          } else {
            node.changed[leftFoot.toString()] = [left[leftFoot], right[rightFoot]];
          }
        }
      }
      leftHand++; rightHand++; leftFoot++; rightFoot++;
    }

    // Any new elements at the end of right.
    for (int i=rightHand; i<right.length; i++) {
      node.added[i.toString()] = right[i];
    }

    // Any removed elements at the end of left.
    for (int i=leftHand; i<left.length; i++) {
      node.removed[i.toString()] = left[i];
    }

    return node;
  }

  void keepMetadata(DiffNode node, Map left, Map right) {
    metadataToKeep.forEach((String key) {
      if (left.containsKey(key) && right.containsKey(key) && left[key] == right[key]) {
        node.metadata[key] = left[key];
      }
    });
  }
}

class UncomparableJsonException implements Exception {
  final String msg;
  const UncomparableJsonException(this.msg);
  String toString() => 'UncomparableJsonException: $msg';
}