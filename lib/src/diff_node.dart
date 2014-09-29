part of shapeshift;

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
  
  void forEachAdded(void ffn(String s, List<Object> o)) {
    added.forEach(ffn);
  }
  
  void forEachRemoved(void ffn(String s, List<Object> o)) {
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

  String toString([String gap=""]) {
    // TODO: This method is a million lines of code because there is not proper pruning in DiffNode.
    Map<String,String> nodeToStrings = new Map();
    if (node != null) {
      node.forEach((String key, DiffNode d) {
        String ds = d.toString(gap+"    ");
        if (ds.isNotEmpty) { nodeToStrings[key] = d.toString(gap+"    "); }
      });
    }
    if (metadata.isEmpty && added.isEmpty && removed.isEmpty && changed.isEmpty && nodeToStrings.values.join().isEmpty) {
      return "";
    }

    String result = "\n";
    if (metadata.isNotEmpty) {
      result += "$gap  metadata: $metadata,\n";
    }
    if (added.isNotEmpty) {
      result += "$gap  added: $added,\n";
    }
    if (removed.isNotEmpty) {
      result += "$gap  removed: $removed,\n";
    }
    if (changed.isNotEmpty) {
      result += "$gap  changed: $changed,\n";
    }
    if (nodeToStrings.values.join().isNotEmpty) {
      result += "$gap  node: {\n";
      nodeToStrings.forEach((key, s) => result += "$gap    $key: $s");
      result += "$gap  }\n";
    }
    return result;
  }
}