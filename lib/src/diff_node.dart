// Copyright 2014 Google Inc. All Rights Reserved.
// Licensed under the Apache License, Version 2.0, found in the LICENSE file.

part of json_diff;

class DiffNode {
  final Map<String,DiffNode> node = new Map<String,DiffNode>();
  final Map<String,Object> added = new Map<String,Object>();
  final Map<String,Object> removed = new Map<String,Object>();
  final Map<String,List<Object>> changed = new Map<String,List<Object>>();
  
  final Map<String,String> metadata = new Map<String,String>();
  
  void operator[]=(String s, DiffNode d) {
    if (d == null) { return; }
    node[s] = d;
  }
  
  DiffNode operator[](String s) {
    return node[s];
  }
  
  bool containsKey(String s) {
    return node.containsKey(s);
  }
  
  void forEach(void ffn(String s, DiffNode dn)) {
    if (node != null) { node.forEach(ffn); }
  }
  
  List<Object> map(void ffn(String s, DiffNode dn)) {
    List result = new List();
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
  
  /// Prune the DiffNode tree. If a DiffNode has nothing added, removed,
  /// changed, nor a node, then will be deleted.
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
