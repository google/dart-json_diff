JSON Diff
=========

Generate a diff between two JSON strings.

Usage
-----

Here's a basic example which features a deleted object, a new object, and a changed object:

```dart
import 'package:json_diff/json_diff.dart';

Map<String,Object> left = '{"a": 2, "b": 3, "c": 5, "d": {"x": 4, "y": 8}}';
Map<String,Object> right = '{"b": 7, "c": 5, "d": {"x": 4, "z": 16}, "e": 11}';
differ = new JsonDiffer(left, right);
DiffNode diff = differ.diff();
diff.added              // => {"e": 11}
diff.removed            // => {"a": 2}
diff.changed            // => {"b": [3, 7]}
diff.node               // => a Map<String,DiffNode>
diff.node['a']          // => a DiffNode
diff.node['a'].added    // => {"z": 16}
diff.node['a'].removed  // => {"y": 8}
```

Contributing
------------

Contributions welcome! Please read the
[contribution guidelines](CONTRIBUTING.md).

Disclaimer
----------

This is not an official Google product.
