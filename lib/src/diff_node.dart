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
  final Map<String,DiffNode> node = new Map<String,DiffNode>();

  /// A Map containing the key/value pairs that were _added_ between the left
  /// JSON and the right.
  final Map<String,Object> added = new Map<String,Object>();

  /// A Map containing the key/value pairs that were _removed_ between the left
  /// JSON and the right.
  final Map<String,Object> removed = new Map<String,Object>();

  /// A Map whose values are 2-element arrays containing the left value and the
  /// right value, corresponding to the mapping key.
  final Map<String,List<Object>> changed = new Map<String,List<Object>>();

  /// Metadata from each JSON string that the JsonDiffer was instructed to
  /// save.
  final Map<String,String> metadata = new Map<String,String>();

  /// A convenience method for `node[]=`.
  void operator[]=(String s, DiffNode d) {
    if (d == null) { return; }
    node[s] = d;
  }

  /// A convenience method for `node[]`.
  DiffNode operator[](String s) {
    return node[s];
  }

  /// A convenience method for `node.containsKey()`.
  bool containsKey(String s) {
    return node.containsKey(s);
  }

  void forEach(void ffn(String s, DiffNode dn)) {
    if (node != null) { node.forEach(ffn); }
  }

  List<Object> map(void ffn(String s, DiffNode dn)) {
    List<void> result = new List();
    if (node != null) {
      forEach((s, dn) { result.add(ffn(s, dn)); });
    }
    return result;
  }

  void forEachOf(String key, void ffn(String s, DiffNode dn)) {
    if (node == null) { return; }
    if (node.containsKey(key)) {
      node[key].forEach(ffn);
    }
  }

  void forEachAdded(void ffn(String s, Object o)) {
    added.forEach(ffn);
  }

  void forEachRemoved(void ffn(String s, Object o)) {
    removed.forEach(ffn);
  }

  void forEachChanged(void ffn(String s, List<Object> o)) {
    changed.forEach(ffn);
  }

  void forAllAdded(void ffn(Object k, Object o), { Map<String,Object> root: const{} }) {
    added.forEach((key, thisNode) => ffn(root, thisNode));
    node.forEach((key, node) {
      root[key] = new Map<String,Object>();
      node.forAllAdded((addedMap, root) => ffn(root, addedMap), root: root[key]);
    });
  }

  Map<String,Object> allAdded() {
    Map<String,Object> thisNode = new Map<String,Object>();
    added.forEach((k,v) { thisNode[k] = v; });
    node.forEach((k,v) {
      Map<String,Object> down = v.allAdded();
      if (down == null) { return; }
      thisNode[k] = v.allAdded();
    });

    if (thisNode.isEmpty) { return null; }
    return thisNode;
  }

  get hasAdded => added.isNotEmpty;
  get hasRemoved => removed.isNotEmpty;
  get hasChanged => changed.isNotEmpty;
  get hasNothing => added.isEmpty && removed.isEmpty && changed.isEmpty && node.isEmpty;

  /// Prunes the DiffNode tree.
  ///
  /// If a child DiffNode has nothing added, removed, changed, nor a node, then it will
  /// be deleted from the parent's [node] Map.
  void prune() {
    List<String> keys = node.keys.toList();
    for (int i=keys.length-1; i>=0; i--) {
      String key = keys[i];
      DiffNode d = node[key];
      d.prune();
      if (d.hasNothing) { node.remove(key); }
    }
  }

  String toString({String gap: '', bool pretty: true}) {
    String result = '';
    String nl = "\n";
    String ss = '  ';
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
      node.forEach((key, d) => result += '$gap${ss}$key: ${d.toString(gap: gap+'    ', pretty: pretty)}');
      result += '$nl${gap}}';
    }
    return result;
  }
}
