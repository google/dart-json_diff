part of shapeshift;

class PackageReporter {
  final Map<String,DiffNode> diff = new Map<String,DiffNode>();
  //JsonDiffer differ;
  String leftPath, rightPath;
  
  PackageReporter(this.leftPath, this.rightPath);
  
  void calculateDiff(String fileName) {
    File leftFile = new File("$leftPath/$fileName");
    File rightFile = new File("$rightPath/$fileName");
    JsonDiffer differ = new JsonDiffer(leftFile.readAsStringSync(), rightFile.readAsStringSync());
    differ.ensureIdentical(["name", "qualifiedName"]);
    diff[fileName] = differ.diff()
        ..metadata['qualifiedName'] = differ.leftJson['qualifiedName']
        ..metadata['name'] = differ.leftJson['name']
        ..metadata['packageName'] = differ.leftJson['packageName'];
  }
  
  void report() {
    diff.forEach((k,v) => reportFile(k));
  }
  
  void reportFile(String fileName) {
    new FileReporter(fileName, diff[fileName]).report();
  }
}

class FileReporter {
  
  final String fileName;
  final DiffNode diff;
  
  FileReporter(this.fileName, this.diff);
  
  void report() {
    if (diff.metadata['packageName'] != null) {
          print(h1(diff.metadata['qualifiedName']));
          reportPackage();
        } else {
          print(h2(diff.metadata['name']));
          reportClass();
        }
  }
  
  void reportPackage() {
    // iterate over the class categories
    diff.forEachOf("classes", (k,v) {
      reportEachClassThing(k, v);
    });
  }
  
  void reportClass() {
    // iterate over the method categories
    diff.forEachOf("methods", (k,v) {
      reportEachMethodThing(k, v);
    });
    
    diff["variables"].forEachAdded((k,v) {
      print("New variable: `${variableSignature(v as Map)}`");
      print("");
    });
    
    diff["variables"].forEachRemoved((k,v) {
      print("Removed variable: `${variableSignature(v as Map)}`");
      print("");
    });
  }
  
  String h1(String s) {
    return "$s\n${'=' * s.length}\n";
  }
  
  String h2(String s) {
    return "$s\n${'-' * s.length}\n";
  }
  
  void reportEachClassThing(String classCategory, DiffNode d) {
    d.forEachAdded((idx, klass) {
      print("New $classCategory '${klass['name']}'");
      print("");
    });
  }
  
  void reportEachMethodThing(String methodCategory, DiffNode d) {
    d.forEachAdded((k, v) {
      //print("New ${singularize(methodCategory)} '$k': ${pretty(v)}");
      print("New ${singularize(methodCategory)} '$k':\n");
      print("```dart");
      print(methodSignature(v as Map));
      print("```");
      print("");
    });
    
    d.forEachRemoved((k, v) {
      //print("New ${singularize(methodCategory)} '$k': ${pretty(v)}");
      if (k == '') { k = diff.metadata['name']; }
      print("Removed ${singularize(methodCategory)} '$k':\n");
      print("```dart");
      print(methodSignature(v as Map, comment: false));
      print("```");
      print("");
    });
          
    // iterate over the methods
    d.forEach((k2,v2) {
      // for a method, iterate over its attributes
      reportEachMethodAttribute(methodCategory, k2, v2);
    });
  }
  
  void reportEachMethodAttribute(String methodCategory, String method, DiffNode attributes) {
    attributes.forEach((name, att) {
      att.forEachAdded((k, v) {
        //print("The '$method' in '$methodCategory' has a new $name: '$k': ${pretty(v)}");
        String category = singularize(methodCategory);
        print("The '$method' ${category} has a new ${singularize(name)}: `${parameterSignature(v as Map)}`");
        print("");
      });
    });
    
    attributes.forEachChanged((k, v) {
      print("The '$method' ${singularize(methodCategory)}'s `${k}` changed:\n");
      print("Was: `${(v as List)[0]}`\n");
      print("Now: `${(v as List)[1]}`");
      print("");
    });
  }
  
  // TODO: just steal this from dartdoc-viewer
  String methodSignature(Map<String,Object> method, { bool comment: true }) {
    String name = method['name'];
    if (name == '') { name = diff.metadata['name']; }
    String s = "${((method['return'] as List)[0] as Map)['outer']} ${name}";
    if (comment) {
      s = "/*\n * ${method['comment']}\n */\n$s";
    }
    List<String> p = new List<String>();
    (method['parameters'] as Map).forEach((k,v) {
      p.add(parameterSignature(v));
    });
    s = "$s(${p.join(', ')})";
    return s;
  }
  
  // TODO: just steal this from dartdoc-viewer
  String parameterSignature(Map<String,Object> parameter) {
    String s = "${((parameter['type'] as List)[0] as Map)['outer']} ${parameter['name']}";
    if (parameter["optional"] && parameter["named"]) {
      s = "{ $s: ${parameter['default']} }";
    }
    return s;
  }
  
  String variableSignature(Map<String,Object> variable) {
    String s = "${((variable['type'] as List)[0] as Map)['outer']} ${variable['name']}";
    if (variable['final'] == true) {
      s = "final $s";
    }
    return s;
  }
  
  String pretty(Object json) {
    return new JsonEncoder.withIndent('  ').convert(json);
  }
}

String singularize(String s) {
  // Remove trailing character. Presumably an 's'.
  return s.substring(0, s.length-1);
}