part of shapeshift;

class MarkdownWriter {
  final IOSink io;
  String h1Buffer, h2Buffer;

  MarkdownWriter(this.io);

  void close() {
    if (h1Buffer != null) {
      io.writeln(h1Buffer);
      io.writeln("_No changes in this package._");
    }
    if (io != stdout) {
      Future.wait([io.close()]);
    }
  }
  
  void writeln(String s) {
    if (h1Buffer != null) {
      io.writeln(h1Buffer);
      h1Buffer = null;
    }
    if (h2Buffer != null) {
      io.writeln(h2Buffer);
      h2Buffer = null;
    }

    io.writeln(s);
  }
  
  void writeBad(String s, String s2) {
    io..writeln("<p style='color: red;'>$s</p>")
        ..writeln("<pre><code style='color: red;'>$s2</code></pre>")
        ..writeln("<hr />");
  }
  
  void writeBlockquote(String s) {
    String joined = s.split("\n").map((m) => "> $m\n").join();
    //print("SPLITTING ON NEWLINES YIELDS:");
    //print(joined);
    io.writeln(joined);
  }

  void writeCodeblockHr(String s) {
    io.writeln("```dart\n${s}\n```\n---");
  }

  void bufferH1(String s) {
    h1Buffer = "$s\n${'=' * s.length}\n";
  }

  void bufferH2(String s) {
    h2Buffer = "$s\n${'-' * s.length}\n";
  }

  void writeMetadata(String packageName) {
    io.writeln("""---
layout: page
title: $packageName
permalink: /$packageName/
---""");
  }

  void writeWasNow(Object theOld, Object theNew, {bool blockquote: false, bool link: false}) {
    String theOldStr = theOld.toString();
    String theNewStr = theNew.toString();
    if (blockquote) {
      if (theOldStr.isEmpty) {
        writeln("Was: _empty_");
      } else {
        writeln("Was:\n");
        writeBlockquote(highlightDeleted(theOldStr, theNewStr));
        //writeBlockquote(theOldStr);
      }
      if (theNewStr.isEmpty) {
        writeln("Now: _empty_");
      } else {
        writeln("Now:\n");
        writeBlockquote(highlightInserted(theOldStr, theNewStr));
        //writeBlockquote(theNewStr);
      }
    } else {
      if (theOldStr.isEmpty) { theOldStr = "_empty_"; }
      else if (link)         { theOldStr = decoratedName(theOldStr); }
      else                   { theOldStr = "`$theOldStr`"; }
      if (theNewStr.isEmpty) { theNewStr = "_empty_"; }
      else if (link)         { theNewStr = mdLinkToDartlang(theNewStr); }
      else                   { theNewStr = "`$theNewStr`"; }
      writeln("Was: $theOldStr\n");
      writeln("Now: $theNewStr");
    }
  }
}

String highlightInserted(String theOld, String theNew) {
  List<Diff> diffResult = diffAndCleanup(theOld, theNew);
  String result = "";
  diffResult.forEach((Diff d) {
    if (d.operation == DIFF_EQUAL) { result += d.text; }
    else if (d.operation == DIFF_INSERT) {
      // TODO: more block element tags
      if (d.text.contains('<blockquote>') || d.text.contains('<p>') || d.text.contains('<pre>')) {
        result += "<div style='background-color: #9F9; display: inline-block; padding: 2px; margin: 0 1px;'>${d.text}</div>";
      } else {
        result += "<span style='background-color: #9F9; padding: 1px;'>${d.text}</span>";
      }
    }
  });
  return result;
}

String highlightDeleted(String theOld, String theNew) {
  List<Diff> diffResult = diffAndCleanup(theOld, theNew);
  String result = "";
  diffResult.forEach((Diff d) {
    if (d.operation == DIFF_EQUAL) { result += d.text; }
    else if (d.operation == DIFF_DELETE) {
      // TODO: more block element tags
      if (d.text.contains('<blockquote>') || d.text.contains('<p>') || d.text.contains('<pre>')) {
        result += "<div style='background-color: #F99; display: inline-block; padding: 1px; margin: 0 1px;'>${d.text}</div>";
      } else {
        result += "<span style='background-color: #F99; padding: 1px; margin: 0 1px;'>${d.text}</span>";
      }
    }
  });
  return result;
}

List<Diff> diffAndCleanup(String theOld, String theNew) {
  List<Diff> result = diff(theOld, theNew);
  cleanupSemantic(result);
  RegExp unclosedTag = new RegExp(r'<[^>]*$');
  RegExp unopenedTag = new RegExp(r'^[^<]*>');
  for (int i=0; i<result.length; i++) {
    Diff d = result[i];
    if (d.text.contains(unclosedTag)) {
      String dirtyDom = unclosedTag.stringMatch(d.text);
      removeFromDiff(d, unclosedTag);
      if (d.operation == DIFF_EQUAL) {
        prependToDiff(result[i+1], dirtyDom);
        if (result[i+2].operation != DIFF_EQUAL) {
          prependToDiff(result[i+2], dirtyDom);
        }
      } else {
        if (result[i+1].operation == DIFF_EQUAL) {
          prependToDiff(result[i+1], dirtyDom);
        } else {
          removeFromDiff(result[i+1], unclosedTag);
          prependToDiff(result[i+2], dirtyDom);
        }
      }
    }
  }
  /*for (int i=result.length-1; i>=0; i--) {
    Diff d = result[i];
    if (d.text.contains(unopenedTag)) {
      String dirtyDom = unopenedTag.stringMatch(d.text);
      removeFromDiff(d, unopenedTag);
      if (d.operation == DIFF_EQUAL) {
        appendToDiff(result[i-1], dirtyDom);
        if (result[i-2].operation != DIFF_EQUAL) {
          appendToDiff(result[i-2], dirtyDom);
        }
      } else {
        if (result[i-1].operation == DIFF_EQUAL) {
          appendToDiff(result[i-1], dirtyDom);
        } else {
          removeFromDiff(result[i-1], unopenedTag);
          appendToDiff(result[i-2], dirtyDom);
        }
      }
    }
  }*/
  return result;
}

void appendToDiff(Diff d, String suffix) {
  d.text = '${d.text}$suffix';
}

void prependToDiff(Diff d, String prefix) {
  d.text = '$prefix${d.text}';
}

void removeFromDiff(Diff d, Pattern p) {
  d.text = d.text.replaceAll(p, '');
}