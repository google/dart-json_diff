// Copyright 2014 Google Inc. All Rights Reserved.
// Licensed under the Apache License, Version 2.0, found in the LICENSE file.

part of json_diff;

/// A hierarchical structure representing the differences between two JSON
/// objects.
///
/// A DiffNode object is returned by [JsonDiffer]'s `diff()` method. DiffNode
/// is a tree structure, referring to more DiffNodes in the `node` property.
/// To access the differences in a DiffNode, refer to the following properties:
///
/// * [added] is a Map of key-value pairs found in the _right_ JSON but not in
///   the _left_ JSON.
/// * [removed] is a Map of key-value pairs found in the _left_ JSON but not in
///   the _right_ JSON.
/// * [changed] is a Map referenceing immediate values that are different
///   between the _left_ and _right_ JSONs. Each key in the Map is a key whose
///   values changed, mapping to a 2-element array which lists the left value
///   and the right value.
/// * [node] is a Map of deeper changes. Each key in this Map is a key whose
///   values changed deeply between the left and right JSONs, mapping to a
///   DiffNode containing those deep changes.
class DiffNode {
  /// A Map of deep changes between the two JSON objects.
  final Map<String, DiffNode> node = <String, DiffNode>{};

  /// A Map containing the key/value pairs that were _added_ between the left
  /// JSON and the right.
  final Map<String, Object> added = <String, Object>{};

  /// A Map containing the key/value pairs that were _removed_ between the left
  /// JSON and the right.
  final Map<String, Object> removed = <String, Object>{};

  /// A Map whose values are 2-element arrays containing the left value and the
  /// right value, corresponding to the mapping key.
  final Map<String, List<Object>> changed = <String, List<Object>>{};

  /// Metadata from each JSON string that the JsonDiffer was instructed to
  /// save.
  final Map<String, Object> metadata = <String, String>{};

  /// A convenience method for `node[]=`.
  void operator []=(String s, DiffNode d) {
    if (d == null) {
      return;
    }
    node[s] = d;
  }

  /// A convenience method for `node[]`.
  DiffNode operator [](String s) {
    return node[s];
  }

  /// A convenience method for `node.containsKey()`.
  bool containsKey(String s) {
    return node.containsKey(s);
  }

  void forEach(void Function(String s, DiffNode dn) ffn) {
    if (node != null) {
      node.forEach(ffn);
    }
  }

  List<Object> map(void Function(String s, DiffNode dn) ffn) {
    final result = <void>[];
    if (node != null) {
      forEach((s, dn) {
        result.add(ffn(s, dn));
      });
    }
    return result;
  }

  void forEachOf(String key, void Function(String s, DiffNode dn) ffn) {
    if (node == null) {
      return;
    }
    if (node.containsKey(key)) {
      node[key].forEach(ffn);
    }
  }

  void forEachAdded(void Function(String s, Object o) ffn) {
    added.forEach(ffn);
  }

  void forEachRemoved(void Function(String s, Object o) ffn) {
    removed.forEach(ffn);
  }

  void forEachChanged(void Function(String s, List<Object> o) ffn) {
    changed.forEach(ffn);
  }

  void forAllAdded(void Function(Object k, Object o) ffn,
      {Map<String, Object> root = const {}}) {
    added.forEach((key, thisNode) => ffn(root, thisNode));
    node.forEach((key, node) {
      root[key] = <String, Object>{};
      node.forAllAdded((addedMap, root) => ffn(root, addedMap),
          root: root[key] as Map<String, Object>);
    });
  }

  Map<String, Object> allAdded() {
    final thisNode = <String, Object>{};
    added.forEach((k, v) {
      thisNode[k] = v;
    });
    node.forEach((k, v) {
      final down = v.allAdded();
      if (down == null) {
        return;
      }
      thisNode[k] = v.allAdded();
    });

    if (thisNode.isEmpty) {
      return null;
    }
    return thisNode;
  }

  bool get hasAdded => added.isNotEmpty;
  bool get hasRemoved => removed.isNotEmpty;
  bool get hasChanged => changed.isNotEmpty;
  bool get hasNothing =>
      added.isEmpty && removed.isEmpty && changed.isEmpty && node.isEmpty;

  /// Prunes the DiffNode tree.
  ///
  /// If a child DiffNode has nothing added, removed, changed, nor a node, then it will
  /// be deleted from the parent's [node] Map.
  void prune() {
    var keys = node.keys.toList();
    for (var i = keys.length - 1; i >= 0; i--) {
      final key = keys[i];
      final d = node[key];
      d.prune();
      if (d.hasNothing) {
        node.remove(key);
      }
    }
  }

  @override
  String toString({String gap = '', bool pretty = true}) {
    var result = '';
    var nl = '\n';
    var ss = '  ';
    if (!pretty) {
      nl = '';
      gap = '';
      ss = '';
    }
    if (metadata.isNotEmpty) {
      result += '$nl${gap}metadata: $metadata,';
    }
    if (added.isNotEmpty) {
      result += '$nl${gap}added: $added,';
    }
    if (removed.isNotEmpty) {
      result += '$nl${gap}removed: $removed,';
    }
    if (changed.isNotEmpty) {
      result += '$nl${gap}changed: $changed,';
    }
    if (node.isNotEmpty) {
      result += '$nl${gap}{$nl';
      node.forEach((key, d) => result +=
          '$gap${ss}$key: ${d.toString(gap: gap + '    ', pretty: pretty)}');
      result += '$nl${gap}}';
    }
    return result;
  }
}
