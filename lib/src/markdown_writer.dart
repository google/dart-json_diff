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
}