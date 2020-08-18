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
/// * [changed] is a Map referencing immediate values that are different
///   between the _left_ and _right_ JSONs. Each key in the Map is a key whose
///   values changed, mapping to a 2-element array which lists the left value
///   and the right value.
/// * [node] is a Map of deeper changes. Each key in this Map is a key whose
///   values changed deeply between the left and right JSONs, mapping to a
///   DiffNode containing those deep changes.
class DiffNode {
  DiffNode(this.path);

  /// A Map of deep changes between the two JSON objects.
  final node = <Object, DiffNode>{};

  /// A Map containing the key/value pairs that were _added_ between the left
  /// JSON and the right.
  final added = <Object, Object>{};

  /// A Map containing the key/value pairs that were _removed_ between the left
  /// JSON and the right.
  final removed = <Object, Object>{};

  /// A Map whose values are 2-element arrays containing the left value and the
  /// right value, corresponding to the mapping key.
  final changed = <Object, List<Object>>{};

  /// A Map of _moved_ elements in the List, where the key is the original
  /// position, and the value is the new position.
  final moved = <int, int>{};

  /// The path, starting from the root, where this [DiffNode] is describing the
  /// left and right JSON, e.g. ["propertyA", 1, "propertyB"].
  final List<Object> path;

  /// A convenience method for `node[]=`.
  void operator []=(Object s, DiffNode d) {
    if (d == null) {
      return;
    }
    node[s] = d;
  }

  /// A convenience method for `node[]`.
  DiffNode operator [](Object s) {
    return node[s];
  }

  /// A convenience method for `node.containsKey()`.
  bool containsKey(Object s) {
    return node.containsKey(s);
  }

  void forEach(void Function(Object s, DiffNode dn) ffn) {
    if (node != null) {
      node.forEach(ffn);
    }
  }

  List<Object> map(void Function(Object s, DiffNode dn) ffn) {
    final result = <void>[];
    if (node != null) {
      forEach((s, dn) {
        result.add(ffn(s, dn));
      });
    }
    return result;
  }

  void forEachOf(String key, void Function(Object s, DiffNode dn) ffn) {
    if (node == null) {
      return;
    }
    if (node.containsKey(key)) {
      node[key].forEach(ffn);
    }
  }

  void forEachAdded(void Function(Object s, Object o) ffn) {
    added.forEach(ffn);
  }

  void forEachRemoved(void Function(Object s, Object o) ffn) {
    removed.forEach(ffn);
  }

  void forEachChanged(void Function(Object s, List<Object> o) ffn) {
    changed.forEach(ffn);
  }

  void forAllAdded(void Function(Object k, Object o) ffn,
      {Map<Object, Object> root = const {}}) {
    added.forEach((key, thisNode) => ffn(root, thisNode));
    node.forEach((key, node) {
      root[key] = <String, Object>{};
      node.forAllAdded((addedMap, root) => ffn(root, addedMap),
          root: root[key] as Map<String, Object>);
    });
  }

  Map<Object, Object> allAdded() {
    final thisNode = <Object, Object>{};
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
  bool get hasMoved => moved.isNotEmpty;
  bool get hasNothing =>
      added.isEmpty &&
      removed.isEmpty &&
      changed.isEmpty &&
      moved.isEmpty &&
      node.isEmpty;

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
  String toString() => _diffToString(this).join('\n');
}

List<String> _diffToString(DiffNode diff) => [
      for (final e in diff.removed.entries) ...[
        '@ Removed from left at path "${[...diff.path, e.key]}":',
        '- ${jsonEncode(e.value)}',
      ],
      for (final e in diff.added.entries) ...[
        '@ Added to right at path "${[...diff.path, e.key]}":',
        '+ ${jsonEncode(e.value)}'
      ],
      for (final e in diff.changed.entries) ...[
        '@ Changed at path "${[...diff.path, e.key]}":',
        '- ${jsonEncode(e.value.first)}',
        '+ ${jsonEncode(e.value.last)}',
      ],
      for (final e in diff.moved.entries) ...[
        '@ Moved at path "${[...diff.path, e.key]}"',
        '${e.key} -> ${e.value}'
      ],
      for (final e in diff.node.entries) ..._diffToString(e.value)
    ];
