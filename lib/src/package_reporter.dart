part of shapeshift;

class PackageReporter {
  final Map<String,DiffNode> diff = new Map<String,DiffNode>();
  final String leftPath, rightPath, out;
  MarkdownWriter io;
  
  PackageReporter(this.leftPath, this.rightPath, { this.out });
  
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

  void calculateAllDiffs() {
    List<FileSystemEntity> leftRawLs = new Directory(leftPath).listSync(recursive: true);
    List<String> leftLs = leftRawLs
        .where((FileSystemEntity f) => f is File)
        .map((File f) => f.path)
        .toList();

    int i = 0;
    leftLs.forEach((String file) {
      i += 1;
      if (i < 120) {
        file = file.replaceFirst(leftPath, "");
        print("$i: diffing $file");
        calculateDiff(file);
      }
    });
  }

  void report() {
    Map<String,PackageSdk> diffsBySubpackage = new Map();
    diff.forEach((String file, DiffNode node) {
      if (node.metadata["packageName"] != null) {
        String subpackage = node.metadata["qualifiedName"];
        if (!diffsBySubpackage.containsKey(subpackage)) {
          diffsBySubpackage[subpackage] = new PackageSdk();
        }
        diffsBySubpackage[subpackage].package = node;
      } else {
        String subpackage = getSubpackage(node);
        if (!diffsBySubpackage.containsKey(subpackage)) {
          diffsBySubpackage[subpackage] = new PackageSdk();
        } else {
          diffsBySubpackage[subpackage].classes.add(node);
        }
      }
    });

    diffsBySubpackage.forEach((String name, PackageSdk p) {
      setIo(name);
      reportFile(name, p.package);
      p.classes.forEach((k) => reportFile(name, k));
      io.close();
    });
  }

  void setIo(String packageName) {
    if (out == null) {
      io = new MarkdownWriter(stdout);
      return;
    }

    Directory dir = new Directory(out)..createSync(recursive: true);
    io = new MarkdownWriter((new File('$out/$packageName.markdown')..createSync(recursive: true)).openWrite());
    io.writeMetadata(packageName);
  }

  void reportFile(String name, DiffNode d) {
    new FileReporter(name, d, io: io).report();
  }

  String getSubpackage(DiffNode node) {
    return (node.metadata["qualifiedName"]).split('.')[0];
  }
}

class FileReporter {

  final String fileName;
  final DiffNode diff;
  final MarkdownWriter io;
  final bool erase = true;

  FileReporter(this.fileName, this.diff, { this.io });

  void report() {
    if (diff == null) {
      return;
    }
    if (diff.metadata['packageName'] != null) {
      io.bufferH1(diff.metadata['qualifiedName']);
      reportPackage();
    } else {
      io.bufferH2("class ${diff.metadata["name"]}");
      reportClass();
    }

    // After reporting, prune and print anything remaining.
    diff.prune();
    String qn = diff.metadata["qualifiedName"];
    diff.metadata.clear();
    String ds = diff.toString();
    if (ds.isNotEmpty) {
      print("${qn} HAS UNRESOLVED NODES:");
      print(ds);
    }
  }

  void reportPackage() {
    // iterate over the class categories
    diff.forEachOf("classes", (k,v) {
      reportEachClassThing(k, v);
    });
  }

  void reportClass() {
    if (diff.hasChanged) {
      diff.forEachChanged((String key, List oldNew) {
        io.writeln("${diff.metadata["name"]}'s `${key}` changed:\n");
        if (key == "comment") {
          io..writeln("Was:\n")
              ..writeBlockquote((oldNew as List<String>)[0])
              ..writeln("Now:\n")
              ..writeBlockquote((oldNew as List<String>)[1]);
        } else {
          io.writeln("Was: `${oldNew[0]}`\n");
          io.writeln("Now: `${oldNew[1]}`");
        }
      });
      diff.changed.clear();
    }

    // iterate over the method categories
    diff.forEachOf("methods", (k,v) {
      reportEachMethodThing(k, v);
    });
    diff.forEachOf("inheritedMethods", (k,v) {
      reportEachMethodThing(k, v, parenthetical: "inherited");
    });
    
    DiffNode variables = diff["variables"];
    if (variables != null) {
      if (variables.hasAdded) {
        io.writeln("New variables:\n");
        io.writeCodeblockHr(variables.added.values.map(variableSignature).join("\n"));
      }
      if (erase) { variables.added.clear(); }

      if (variables.hasRemoved) {
        io.writeln("Removed variables:\n");
        io.writeCodeblockHr(variables.removed.values.map(variableSignature).join("\n"));
      }
      if (erase) { variables.removed.clear(); }

      if (variables.hasChanged) {
        variables.forEachChanged((k,v) {
          print("CHANGED: $k, $v");
        });
      }

      variables.forEach((key, variable) {
        if (variable.hasChanged) {
          variable.forEachChanged((attribute, value) {
            io.writeln("The [$key](#) variable's `$attribute` changed:\n");
            io.writeln("Was: `${value[0]}`\n");
            io.writeln("Now: `${value[1]}`\n");
            io.writeln("---\n");
          });
        }
        if (erase) { variable.changed.clear(); }
        
        if (variable.node.isNotEmpty) {
          variable.node.forEach((s, dn) {
            io.writeBad("The [$key](#) variable's `$s` has changed:\n", dn.toString(pretty: false));
          });
        }
        if (erase) { variable.node.clear(); }
      });
    }
  }

  String comment(String c) {
    if (c.isEmpty) { return ""; }
    return c.split("\n").map((String x) => "/// $x\n").join("");
  }

  void reportEachClassThing(String classCategory, DiffNode d) {
    d.forEachAdded((idx, klass) {
      io.writeln("New $classCategory [${klass['name']}](#)");
      io.writeln("\n---\n");
    });
    if (erase) { d.added.clear(); }
  }
  
  void reportEachMethodThing(String methodCategory, DiffNode d, { String parenthetical:""}) {
    if (parenthetical.isNotEmpty) { parenthetical = " _($parenthetical)_"; }
    d.forEachAdded((k, v) {
      //print("New ${singularize(methodCategory)} '$k': ${pretty(v)}");
      io.writeln("New ${singularize(methodCategory)}$parenthetical [$k](#):\n");
      io.writeCodeblockHr(methodSignature(v as Map));
    });
    if (erase) { d.added.clear(); }
    
    d.forEachRemoved((k, v) {
      //print("New ${singularize(methodCategory)} '$k': ${pretty(v)}");
      if (k == '') { k = diff.metadata['name']; }
      io.writeln("Removed ${singularize(methodCategory)}$parenthetical [$k](#):\n");
      io.writeCodeblockHr(methodSignature(v as Map, includeComment: false));
    });
    if (erase) { d.removed.clear(); }
          
    // iterate over the methods
    d.forEach((k, v) {
      // for a method, iterate over its attributes
      reportEachMethodAttribute(methodCategory, k, v);
    });
  }
  
  void reportEachMethodAttribute(String methodCategory, String method, DiffNode attributes) {
    attributes.forEach((name, att) {
      att.forEachAdded((k, v) {
        //print("The '$method' in '$methodCategory' has a new $name: '$k': ${pretty(v)}");
        String category = singularize(methodCategory);
        io.writeln("The [$method](#) ${category} has a new ${singularize(name)}: `${parameterSignature(v as Map)}`");
        io.writeln("\n---\n");
      });
      if (erase) { att.added.clear(); }
    });
    
    attributes.forEachChanged((String key, List oldNew) {
      io.writeln("The [$method](#) ${singularize(methodCategory)}'s `${key}` changed:\n");
      if (key == "comment") {
        io..writeln("Was:\n")
            ..writeBlockquote((oldNew as List<String>)[0])
            ..writeln("Now:\n")
            ..writeBlockquote((oldNew as List<String>)[1]);
      } else {
        io.writeln("Was: `${oldNew[0]}`\n");
        io.writeln("Now: `${oldNew[1]}`");
      }
      io.writeln("\n---\n");
    });
    if (erase) { attributes.changed.clear(); }
  }
  
  // TODO: just steal this from dartdoc-viewer
  String methodSignature(Map<String,Object> method, { bool includeComment: true }) {
    String name = method['name'];
    String type = simpleType(method["return"]);
    if (name == '') { name = diff.metadata['name']; }
    String s = "$type $name";
    if (includeComment) {
      s = comment(method['comment']) + s;
    }
    List<String> p = new List<String>();
    (method['parameters'] as Map).forEach((k, v) {
      p.add(parameterSignature(v));
    });
    s = "$s(${p.join(', ')})";
    return s;
  }

  String simpleType(List<Map> t) {
    // TODO more than the first
    String type = t[0]['outer'];
    if (type.startsWith("dart-core.")) {
      type = type.replaceFirst("dart-core.", "");
    }
    return type;
  }

  // TODO: just steal this from dartdoc-viewer
  String parameterSignature(Map<String,Object> parameter) {
    String type = simpleType(parameter['type']);
    String s = "$type ${parameter['name']}";
    if (parameter["optional"] && parameter["named"]) {
      s = "{ $s: ${parameter['default']} }";
    }
    return s;
  }
  
  String variableSignature(Map<String,Object> variable) {
    String type = simpleType(variable['type']);
    String s = "$type ${variable['name']};";
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

class PackageSdk {
  final List<DiffNode> classes = new List();
  DiffNode package;
}