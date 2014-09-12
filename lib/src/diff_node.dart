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
}