[![Build Status](https://github.com/dart-lang/markdown/workflows/Dart%20CI/badge.svg)](https://github.com/dart-lang/markdown/actions?query=workflow%3A"Dart+CI"+branch%3Amaster)

Generate a diff between two JSON strings.

Usage
-----

Here's a basic example which features a deleted object, a new object, a changed
object, and a deeply changed object:

```dart
import 'package:json_diff/json_diff.dart';

final left = {"a": 2, "b": 3, "c": 5, "d": {"x": 4, "y": 8}};
final right = {"b": 7, "c": 5, "d": {"x": 4, "z": 16}, "e": 11};
final differ = JsonDiffer.fromJson(left, right);
DiffNode diff = differ.diff();
print(diff.added);              // => {"e": 11}
print(diff.removed);            // => {"a": 2}
print(diff.changed);            // => {"b": [3, 7]}
print(diff.node);               // => a Map<String,DiffNode>
print(diff.node['d']);          // => a DiffNode
print(diff.node['d'].added);    // => {"z": 16}
print(diff.node['d'].removed);  // => {"y": 8}
```

So that's pretty fun. So when you diff two JSON strings, you get back a
DiffNode. A DiffNode is a heirarchical structure that vaguely mirrors the
structure of the input JSON strings. In this example, the top-level DiffNode we
got back has

* an `added` property, which is a Map of top-level properties that
  were _not_ found in `left`, and _were_ found in `right`.
* a `removed` property, which is a Map of top-level properties that were found
  in `left`, but were `not` found in `right`.
* a `changed` property, which is a Map of top-level properties whose values are
  different in `left` and in `right`. The values in this Map are two-element
  Arrays. The 0th element is the old value (from `left`), and the 1st element
  is the new value (from `right`).
* a `moved` property, which is a Map of indexes, where key is the original index 
  of an element, and value is index in the changed list.
* a `node` property, a Map of the properties found in both `left` and `right`
  that have deep differences. The values of this Map are more DiffNodes.
* a `path` property, which is a List of indexes, describing the path from the root
  where this DiffNode is operating.

Contributing
------------

Contributions welcome! Please read the
[contribution guidelines](CONTRIBUTING.md).

Disclaimer
----------

This is not an official Google product.
