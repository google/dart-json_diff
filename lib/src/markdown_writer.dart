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
    io.writeln(s.split("\n").map((m) => "> $m\n").join());
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
        writeBlockquote(theOldStr);
      }
      if (theNewStr.isEmpty) {
        writeln("Now: _empty_");
      } else {
        writeln("Now:\n");
        writeBlockquote(theNewStr);
      }
    } else {
      if (theOldStr.isEmpty) { theOldStr = "_empty_"; }
      else if (link)         { theOldStr = "[$theOldStr](#)"; }
      else                   { theOldStr = "`$theOldStr`"; }
      if (theNewStr.isEmpty) { theNewStr = "_empty_"; }
      else if (link)         { theNewStr = "[$theNewStr](#)"; }
      else                   { theNewStr = "`$theNewStr`"; }
      writeln("Was: $theOldStr\n");
      writeln("Now: $theNewStr");
    }
  }
}